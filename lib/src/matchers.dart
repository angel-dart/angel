import 'package:matcher/matcher.dart';
import 'context_aware.dart';
import 'context_validator.dart';

final RegExp _alphaDash = RegExp(r'^[A-Za-z0-9_-]+$');
final RegExp _alphaNum = RegExp(r'^[A-Za-z0-9]+$');
final RegExp _email = RegExp(
    r"^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$");
final RegExp _url = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)');

/// Asserts that a `String` is alphanumeric, but also lets it contain dashes or underscores.
final Matcher isAlphaDash = predicate(
    (value) => value is String && _alphaDash.hasMatch(value),
    'alphanumeric (dashes and underscores are allowed)');

/// Asserts that a `String` is alphanumeric, but also lets it contain dashes or underscores.
///
final Matcher isAlphaNum = predicate(
    (value) => value is String && _alphaNum.hasMatch(value), 'alphanumeric');

/// Asserts that a value either equals `true` or `false`.
final Matcher isBool = predicate((value) => value is bool, 'a bool');

///  Asserts that a `String` complies to the RFC 5322 e-mail standard.
final Matcher isEmail = predicate(
    (value) => value is String && _email.hasMatch(value),
    'a valid e-mail address');

/// Asserts that a value is an `int`.
final Matcher isInt = predicate((value) => value is int, 'an integer');

/// Asserts that a value is a `num`.
final Matcher isNum = predicate((value) => value is num, 'a number');

/// Asserts that a value is a `String`.
final Matcher isString = predicate((value) => value is String, 'a string');

/// Asserts that a value is a non-empty `String`.
final Matcher isNonEmptyString = predicate(
    (value) => value is String && value.trim().isNotEmpty,
    'a non-empty string');

/// Asserts that a value, presumably from a checkbox, is positive.
final Matcher isChecked =
    isIn(const ['yes', 'checked', 'on', '1', 1, 1.0, true, 'true']);

/// Ensures that a string is an ISO-8601 date string.
final Matcher isIso8601DateString = predicate(
  (x) {
    try {
      return x is String && DateTime.parse(x) != null;
    } catch (_) {
      return false;
    }
  },
  'a valid ISO-8601 date string.',
);

///  Asserts that a `String` is an `http://` or `https://` URL.
///
/// The regular expression used:
/// ```
/// https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)
/// ```
final Matcher isUrl = predicate(
    (value) => value is String && _url.hasMatch(value),
    'a valid url, starting with http:// or https://');

/// Use [isUrl] instead.
@deprecated
final Matcher isurl = isUrl;

/// Enforces a minimum length on a string.
Matcher minLength(int length) => predicate(
    (value) => value is String && value.length >= length,
    'a string at least $length character(s) long');

/// Limits the maximum length of a string.
Matcher maxLength(int length) => predicate(
    (value) => value is String && value.length <= length,
    'a string no longer than $length character(s) long');

/// Asserts that for a key `x`, the context contains an identical item `x_confirmed`.
ContextAwareMatcher isConfirmed = predicateWithContext(
  (item, key, context, matchState) {
    return equals(item).matches(context['${key}_confirmed'], matchState);
  },
  'is confirmed',
);

/// Asserts that for a key `x`, the value of `x` is **not equal to** the value for [key].
ContextAwareMatcher differentFrom(String key) {
  return predicateWithContext(
    (item, key, context, matchState) {
      return !equals(item).matches(context[key], matchState);
    },
    'is different from the value of "$key"',
  );
}

/// Asserts that for a key `x`, the value of `x` is **equal to** the value for [key].
ContextAwareMatcher sameAs(String key) {
  return predicateWithContext(
    (item, key, context, matchState) {
      return equals(item).matches(context[key], matchState);
    },
    'is equal to the value of "$key"',
  );
}

/// Assert that a key `x` is present, if *all* of the given [keys] are as well.
ContextValidator requiredIf(Iterable<String> keys) =>
    _require((ctx) => keys.every(ctx.containsKey));

/// Assert that a key `x` is present, if *any* of the given [keys] are as well.
ContextValidator requiredAny(Iterable<String> keys) =>
    _require((ctx) => keys.any(ctx.containsKey));

/// Assert that a key `x` is present, if *at least one* of the given [keys] is not.
ContextValidator requiredWithout(Iterable<String> keys) =>
    _require((ctx) => !keys.every(ctx.containsKey));

/// Assert that a key `x` is present, if *none* of the given [keys] are.
ContextValidator requiredWithoutAll(Iterable<String> keys) =>
    _require((ctx) => !keys.any(ctx.containsKey));

ContextValidator _require(bool Function(Map) f) {
  return ContextValidator(
    (key, context) => f(context) && context.containsKey(key),
    (desc, key, _) => StringDescription('Missing required field "$key".'),
  );
}
