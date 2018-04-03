// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library provides internationalization and localization. This includes
/// message formatting and replacement, date and number formatting and parsing,
/// and utilities for working with Bidirectional text.
///
/// This is part of the [intl package]
/// (https://pub.dartlang.org/packages/intl).
///
/// For things that require locale or other data, there are multiple different
/// ways of making that data available, which may require importing different
/// libraries. See the class comments for more details.
///
/// There is also a simple example application that can be found in the
/// [example/basic](https://github.com/dart-lang/intl/tree/master/example/basic)
/// directory.
library intl;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'date_symbols.dart';
import 'number_symbols.dart';
import 'number_symbols_data.dart';
import 'src/date_format_internal.dart';
import 'src/intl_helpers.dart';
import 'package:intl/src/plural_rules.dart' as plural_rules;

part 'src/intl/bidi_formatter.dart';
part 'src/intl/bidi_utils.dart';

part 'src/intl/compact_number_format.dart';
part 'src/intl/date_format.dart';
part 'src/intl/date_format_field.dart';
part 'src/intl/date_format_helpers.dart';
part 'src/intl/number_format.dart';

/// The Intl class provides a common entry point for internationalization
/// related tasks. An Intl instance can be created for a particular locale
/// and used to create a date format via `anIntl.date()`. Static methods
/// on this class are also used in message formatting.
///
/// Examples:
///      today(date) => Intl.message(
///          "Today's date is $date",
///          name: 'today',
///          args: [date],
///          desc: 'Indicate the current date',
///          examples: const {'date' : 'June 8, 2012'});
///      print(today(new DateTime.now().toString());
///
///      howManyPeople(numberOfPeople, place) => Intl.plural(
///            zero: 'I see no one at all',
///            one: 'I see one other person',
///            other: 'I see $numberOfPeople other people')} in $place.''',
///          name: 'msg',
///          args: [numberOfPeople, place],
///          desc: 'Description of how many people are seen in a place.',
///          examples: const {'numberOfPeople': 3, 'place': 'London'});
///
/// Calling `howManyPeople(2, 'Athens');` would
/// produce "I see 2 other people in Athens." as output in the default locale.
/// If run in a different locale it would produce appropriately translated
/// output.
///
/// For more detailed information on messages and localizing them see
/// the main [package documentation](https://pub.dartlang.org/packages/intl)
///
/// You can set the default locale.
///       Intl.defaultLocale = "pt_BR";
///
/// To temporarily use a locale other than the default, use the `withLocale`
/// function.
///       var todayString = new DateFormat("pt_BR").format(new DateTime.now());
///       print(withLocale("pt_BR", () => today(todayString));
///
/// See `tests/message_format_test.dart` for more examples.
//TODO(efortuna): documentation example involving the offset parameter?

class Intl {
  /// String indicating the locale code with which the message is to be
  /// formatted (such as en-CA).
  String _locale;

  /// The default locale. This defaults to being set from systemLocale, but
  /// can also be set explicitly, and will then apply to any new instances where
  /// the locale isn't specified. Note that a locale parameter to
  /// [Intl.withLocale]
  /// will supercede this value while that operation is active. Using
  /// [Intl.withLocale] may be preferable if you are using different locales
  /// in the same application.
  static String get defaultLocale {
    var zoneLocale = Zone.current[#Intl.locale];
    return zoneLocale == null ? _defaultLocale : zoneLocale;
  }

  static set defaultLocale(String newLocale) {
    _defaultLocale = newLocale;
  }

  static String _defaultLocale;

  /// The system's locale, as obtained from the window.navigator.language
  /// or other operating system mechanism. Note that due to system limitations
  /// this is not automatically set, and must be set by importing one of
  /// intl_browser.dart or intl_standalone.dart and calling findSystemLocale().
  static String systemLocale = 'en_US';

  /// Return a new date format using the specified [pattern].
  /// If [desiredLocale] is not specified, then we default to [locale].
  DateFormat date([String pattern, String desiredLocale]) {
    var actualLocale = (desiredLocale == null) ? locale : desiredLocale;
    return new DateFormat(pattern, actualLocale);
  }

  /// Constructor optionally [aLocale] for specifics of the language
  /// locale to be used, otherwise, we will attempt to infer it (acceptable if
  /// Dart is running on the client, we can infer from the browser/client
  /// preferences).
  Intl([String aLocale]) {
    _locale = aLocale != null ? aLocale : getCurrentLocale();
  }

  /// Use this for a message that will be translated for different locales. The
  /// expected usage is that this is inside an enclosing function that only
  /// returns the value of this call and provides a scope for the variables that
  /// will be substituted in the message.
  ///
  /// The [message_str] is the string to be translated, which may be
  /// interpolated based on one or more variables. The [name] of the message
  /// must match the enclosing function name. For methods, it can also be
  /// className_methodName. So for a method hello in class Simple, the name can
  /// be either "hello" or "Simple_hello". The name must also be globally unique
  /// in the program, so the second form can make it easier to distinguish
  /// messages with the same name but in different classes.
  ///
  /// The [args] repeats the arguments of the enclosing
  /// function, [desc] provides a description of usage,
  /// [examples] is a Map of examples for each interpolated variable.
  /// For example
  ///
  ///       hello(yourName) => Intl.message(
  ///         "Hello, $yourName",
  ///         name: "hello",
  ///         args: [yourName],
  ///         desc: "Say hello",
  ///         examples = const {"yourName": "Sparky"}.
  ///
  /// The source code will be processed via the analyzer to extract out the
  /// message data, so only a subset of valid Dart code is accepted. In
  /// particular, everything must be literal and cannot refer to variables
  /// outside the scope of the enclosing function. The [examples] map must be a
  /// valid const literal map. Similarly, the [desc] argument must be a single,
  /// simple string. These two arguments will not be used at runtime but will be
  /// extracted from the source code and used as additional data for
  /// translators. For more information see the "Messages" section of the main
  /// [package documentation] (https://pub.dartlang.org/packages/intl).
  ///
  /// The [name] and [args] arguments are required, and are used at runtime
  /// to look up the localized version and pass the appropriate arguments to it.
  /// We may in the future modify the code during compilation to make manually
  /// passing those arguments unnecessary.
  static String message(String message_str,
          {String desc: '',
          Map<String, dynamic> examples: const {},
          String locale,
          String name,
          List args,
          String meaning}) =>
      _message(message_str, locale, name, args, meaning);

  /// Omit the compile-time only parameters so dart2js can see to drop them.
  static _message(String message_str, String locale, String name, List args,
      String meaning) {
    return messageLookup.lookupMessage(
        message_str, locale, name, args, meaning);
  }

  /// Return the locale for this instance. If none was set, the locale will
  /// be the default.
  String get locale => _locale;

  /// Given [newLocale] return a locale that we have data for that is similar
  /// to it, if possible.
  ///
  /// If [newLocale] is found directly, return it. If it can't be found, look up
  /// based on just the language (e.g. 'en_CA' -> 'en'). Also accepts '-'
  /// as a separator and changes it into '_' for lookup, and changes the
  /// country to uppercase.
  ///
  /// There is a special case that if a locale named "fallback" is present
  /// and has been initialized, this will return that name. This can be useful
  /// for messages where you don't want to just use the text from the original
  /// source code, but wish to have a universal fallback translation.
  ///
  /// Note that null is interpreted as meaning the default locale, so if
  /// [newLocale] is null the default locale will be returned.
  static String verifiedLocale(String newLocale, Function localeExists,
      {Function onFailure: _throwLocaleError}) {
    // TODO(alanknight): Previously we kept a single verified locale on the Intl
    // object, but with different verification for different uses, that's more
    // difficult. As a result, we call this more often. Consider keeping
    // verified locales for each purpose if it turns out to be a performance
    // issue.
    if (newLocale == null) {
      return verifiedLocale(getCurrentLocale(), localeExists,
          onFailure: onFailure);
    }
    if (localeExists(newLocale)) {
      return newLocale;
    }
    for (var each in [
      canonicalizedLocale(newLocale),
      shortLocale(newLocale),
      "fallback"
    ]) {
      if (localeExists(each)) {
        return each;
      }
    }
    return onFailure(newLocale);
  }

  /// The default action if a locale isn't found in verifiedLocale. Throw
  /// an exception indicating the locale isn't correct.
  static String _throwLocaleError(String localeName) {
    throw new ArgumentError("Invalid locale '$localeName'");
  }

  /// Return the short version of a locale name, e.g. 'en_US' => 'en'
  static String shortLocale(String aLocale) {
    if (aLocale.length < 2) return aLocale;
    return aLocale.substring(0, 2).toLowerCase();
  }

  /// Return the name [aLocale] turned into xx_YY where it might possibly be
  /// in the wrong case or with a hyphen instead of an underscore. If
  /// [aLocale] is null, for example, if you tried to get it from IE,
  /// return the current system locale.
  static String canonicalizedLocale(String aLocale) {
    // Locales of length < 5 are presumably two-letter forms, or else malformed.
    // We return them unmodified and if correct they will be found.
    // Locales longer than 6 might be malformed, but also do occur. Do as
    // little as possible to them, but make the '-' be an '_' if it's there.
    // We treat C as a special case, and assume it wants en_ISO for formatting.
    // TODO(alanknight): en_ISO is probably not quite right for the C/Posix
    // locale for formatting. Consider adding C to the formats database.
    if (aLocale == null) return getCurrentLocale();
    if (aLocale == "C") return "en_ISO";
    if (aLocale.length < 5) return aLocale;
    if (aLocale[2] != '-' && (aLocale[2] != '_')) return aLocale;
    var region = aLocale.substring(3);
    // If it's longer than three it's something odd, so don't touch it.
    if (region.length <= 3) region = region.toUpperCase();
    return '${aLocale[0]}${aLocale[1]}_$region';
  }

  /// Format a message differently depending on [howMany]. Normally used
  /// as part of an `Intl.message` text that is to be translated.
  /// Selects the correct plural form from
  /// the provided alternatives. The [other] named argument is mandatory.
  static String plural(int howMany,
      {String zero,
      String one,
      String two,
      String few,
      String many,
      String other,
      String desc,
      Map<String, dynamic> examples,
      String locale,
      String name,
      List args,
      String meaning}) {
    // Call our internal method, dropping examples and desc because they're not
    // used at runtime and we want them to be optimized away.
    return _plural(howMany,
        zero: zero,
        one: one,
        two: two,
        few: few,
        many: many,
        other: other,
        locale: locale,
        name: name,
        args: args,
        meaning: meaning);
  }

  static String _plural(int howMany,
      {String zero,
      String one,
      String two,
      String few,
      String many,
      String other,
      String locale,
      String name,
      List args,
      String meaning}) {
    // Look up our translation, but pass in a null message so we don't have to
    // eagerly evaluate calls that may not be necessary.
    var translated = _message(null, locale, name, args, meaning);

    /// If there's a translation, return it, otherwise evaluate with our
    /// original text.
    return translated ??
        pluralLogic(howMany,
            zero: zero,
            one: one,
            two: two,
            few: few,
            many: many,
            other: other,
            locale: locale);
  }

  /// Internal: Implements the logic for plural selection - use [plural] for
  /// normal messages.
  static pluralLogic(int howMany,
      {zero, one, two, few, many, other, String locale, String meaning}) {
    if (other == null) {
      throw new ArgumentError("The 'other' named argument must be provided");
    }
    if (howMany == null) {
      throw new ArgumentError("The howMany argument to plural cannot be null");
    }
    // If there's an explicit case for the exact number, we use it. This is not
    // strictly in accord with the CLDR rules, but it seems to be the
    // expectation. At least I see e.g. Russian translations that have a zero
    // case defined. The rule for that locale will never produce a zero, and
    // treats it as other. But it seems reasonable that, even if the language
    // rules treat zero as other, we might want a special message for zero.
    if (howMany == 0 && zero != null) return zero;
    if (howMany == 1 && one != null) return one;
    if (howMany == 2 && two != null) return two;
    var pluralRule = _pluralRule(locale, howMany);
    var pluralCase = pluralRule();
    switch (pluralCase) {
      case plural_rules.PluralCase.ZERO:
        return zero ?? other;
      case plural_rules.PluralCase.ONE:
        return one ?? other;
      case plural_rules.PluralCase.TWO:
        return two ?? few ?? other;
      case plural_rules.PluralCase.FEW:
        return few ?? other;
      case plural_rules.PluralCase.MANY:
        return many ?? other;
      case plural_rules.PluralCase.OTHER:
        return other;
      default:
        throw new ArgumentError.value(
            howMany, "howMany", "Invalid plural argument");
    }
  }

  static var _cachedPluralRule;
  static String _cachedPluralLocale;

  static _pluralRule(String locale, int howMany) {
    plural_rules.startRuleEvaluation(howMany);
    var verifiedLocale = Intl.verifiedLocale(
        locale, plural_rules.localeHasPluralRules,
        onFailure: (locale) => 'default');
    if (_cachedPluralLocale == verifiedLocale) {
      return _cachedPluralRule;
    } else {
      _cachedPluralRule = plural_rules.pluralRules[verifiedLocale];
      _cachedPluralLocale = verifiedLocale;
      return _cachedPluralRule;
    }
  }

  /// Format a message differently depending on [targetGender].
  static String gender(String targetGender,
      {String female,
      String male,
      String other,
      String desc,
      Map<String, dynamic> examples,
      String locale,
      String name,
      List args,
      String meaning}) {
    // Call our internal method, dropping args and desc because they're not used
    // at runtime and we want them to be optimized away.
    return _gender(targetGender,
        male: male,
        female: female,
        other: other,
        locale: locale,
        name: name,
        args: args,
        meaning: meaning);
  }

  static String _gender(String targetGender,
      {String female,
      String male,
      String other,
      String desc,
      Map<String, dynamic> examples,
      String locale,
      String name,
      List args,
      String meaning}) {
    // Look up our translation, but pass in a null message so we don't have to
    // eagerly evaluate calls that may not be necessary.
    var translated = _message(null, locale, name, args, meaning);

    /// If there's a translation, return it, otherwise evaluate with our
    /// original text.
    return translated ??
        genderLogic(targetGender,
            female: female, male: male, other: other, locale: locale);
  }

  /// Internal: Implements the logic for gender selection - use [gender] for
  /// normal messages.
  static genderLogic(String targetGender,
      {female, male, other, String locale}) {
    if (other == null) {
      throw new ArgumentError("The 'other' named argument must be specified");
    }
    switch (targetGender) {
      case "female":
        return female == null ? other : female;
      case "male":
        return male == null ? other : male;
      default:
        return other;
    }
  }

  /// Format a message differently depending on [choice]. We look up the value
  /// of [choice] in [cases] and return the result, or an empty string if
  /// it is not found. Normally used as part
  /// of an Intl.message message that is to be translated.
  static String select(Object choice, Map<String, String> cases,
      {String desc,
      Map<String, dynamic> examples,
      String locale,
      String name,
      List args,
      String meaning}) {
    return _select(choice, cases,
        locale: locale, name: name, args: args, meaning: meaning);
  }

  static String _select(Object choice, Map<String, String> cases,
      {String locale, String name, List args, String meaning}) {
    // Look up our translation, but pass in a null message so we don't have to
    // eagerly evaluate calls that may not be necessary.
    var translated = _message(null, locale, name, args, meaning);

    /// If there's a translation, return it, otherwise evaluate with our
    /// original text.
    return translated ?? selectLogic(choice, cases);
  }

  /// Internal: Implements the logic for select - use [select] for
  /// normal messages.
  static selectLogic(Object choice, Map<String, String> cases) {
    // Allow passing non-strings, e.g. enums to a select.
    choice = "$choice";
    var exact = cases[choice];
    if (exact != null) return exact;
    var other = cases["other"];
    if (other == null)
      throw new ArgumentError("The 'other' case must be specified");
    return other;
  }

  /// Run [function] with the default locale set to [locale] and
  /// return the result.
  ///
  /// This is run in a zone, so async operations invoked
  /// from within [function] will still have the locale set.
  ///
  /// In simple usage [function] might be a single
  /// `Intl.message()` call or number/date formatting operation. But it can
  /// also be an arbitrary function that calls multiple Intl operations.
  ///
  /// For example
  ///
  ///       Intl.withLocale("fr", () => new NumberFormat.format(123456));
  ///
  /// or
  ///
  ///       hello(name) => Intl.message(
  ///           "Hello $name.",
  ///           name: 'hello',
  ///           args: [name],
  ///           desc: 'Say Hello');
  ///       Intl.withLocale("zh", new Timer(new Duration(milliseconds:10),
  ///           () => print(hello("World")));
  static withLocale(String locale, function()) {
    var canonical = Intl.canonicalizedLocale(locale);
    return runZoned(function, zoneValues: {#Intl.locale: canonical});
  }

  /// Accessor for the current locale. This should always == the default locale,
  /// unless for some reason this gets called inside a message that resets the
  /// locale.
  static String getCurrentLocale() {
    if (defaultLocale == null) defaultLocale = systemLocale;
    return defaultLocale;
  }

  toString() => "Intl($locale)";
}

/// Convert a string to beginning of sentence case, in a way appropriate to the
/// locale.
///
/// Currently this just converts the first letter to uppercase, which works for
/// many locales, and we have the option to extend this to handle more cases
/// without changing the API for clients. It also hard-codes the case of
/// dotted i in Turkish and Azeri.
String toBeginningOfSentenceCase(String input, [String locale]) {
  if (input == null || input.isEmpty) return input;
  return "${_upperCaseLetter(input[0], locale)}${input.substring(1)}";
}

/// Convert the input single-letter string to upper case. A trivial
/// hard-coded implementation that only handles simple upper case
/// and the dotted i in Turkish/Azeri.
///
/// Private to the implementation of [toBeginningOfSentenceCase].
// TODO(alanknight): Consider hard-coding other important cases.
// See http://www.unicode.org/Public/UNIDATA/SpecialCasing.txt
// TODO(alanknight): Alternatively, consider toLocaleUpperCase in browsers.
// See also https://github.com/dart-lang/sdk/issues/6706
String _upperCaseLetter(String input, String locale) {
  // Hard-code the important edge case of i->İ
  if (locale != null) {
    if (input == "i" && locale.startsWith("tr") || locale.startsWith("az")) {
      return "\u0130";
    }
  }
  return input.toUpperCase();
}
