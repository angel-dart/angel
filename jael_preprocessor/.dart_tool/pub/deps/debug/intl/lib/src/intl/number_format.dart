// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of intl;

/// The function that we pass internally to NumberFormat to get
/// the appropriate pattern (e.g. currency)
typedef String _PatternGetter(NumberSymbols symbols);

/// Provides the ability to format a number in a locale-specific way. The
/// format is specified as a pattern using a subset of the ICU formatting
/// patterns.
///
/// - `0` A single digit
/// - `#` A single digit, omitted if the value is zero
/// - `.` Decimal separator
/// - `-` Minus sign
/// - `,` Grouping separator
/// - `E` Separates mantissa and expontent
/// - `+` - Before an exponent, to say it should be prefixed with a plus sign.
/// - `%` - In prefix or suffix, multiply by 100 and show as percentage
/// - `‰ (\u2030)` In prefix or suffix, multiply by 1000 and show as per mille
/// - `¤ (\u00A4)` Currency sign, replaced by currency name
/// - `'` Used to quote special characters
/// - `;` Used to separate the positive and negative patterns (if both present)
///
/// For example,
///       var f = new NumberFormat("###.0#", "en_US");
///       print(f.format(12.345));
///       ==> 12.34
/// If the locale is not specified, it will default to the current locale. If
/// the format is not specified it will print in a basic format with at least
/// one integer digit and three fraction digits.
///
/// There are also standard patterns available via the special constructors.
/// e.g.
///       var percent = new NumberFormat.percentFormat("ar");
///       var eurosInUSFormat = new NumberFormat.currency(locale: "en_US",
///           symbol: "€");
/// There are four such constructors: decimalFormat, percentFormat,
/// scientificFormat and currencyFormat. However, at the moment,
/// scientificFormat prints only as equivalent to "#E0" and does not take
/// into account significant digits. The currencyFormat will default to the
/// three-letter name of the currency if no explicit name/symbol is provided.
class NumberFormat {
  /// Variables to determine how number printing behaves.
  // TODO(alanknight): If these remain as variables and are set based on the
  // pattern, can we make them final?
  String _negativePrefix = '-';
  String _positivePrefix = '';
  String _negativeSuffix = '';
  String _positiveSuffix = '';

  /// How many numbers in a group when using punctuation to group digits in
  /// large numbers. e.g. in en_US: "1,000,000" has a grouping size of 3 digits
  /// between commas.
  int _groupingSize = 3;

  /// In some formats the last grouping size may be different than previous
  /// ones, e.g. Hindi.
  int _finalGroupingSize = 3;

  /// Set to true if the format has explicitly set the grouping size.
  bool _groupingSizeSetExplicitly = false;
  bool _decimalSeparatorAlwaysShown = false;
  bool _useSignForPositiveExponent = false;
  bool _useExponentialNotation = false;

  /// Explicitly store if we are a currency format, and so should use the
  /// appropriate number of decimal digits for a currency.
  // TODO(alanknight): Handle currency formats which are specified in a raw
  /// pattern, not using one of the currency constructors.
  bool _isForCurrency = false;

  int maximumIntegerDigits = 40;
  int minimumIntegerDigits = 1;
  int maximumFractionDigits = 3;
  int minimumFractionDigits = 0;
  int minimumExponentDigits = 0;
  int _significantDigits = 0;

  ///  How many significant digits should we print.
  ///
  ///  Note that if significantDigitsInUse is the default false, this
  ///  will be ignored.
  int get significantDigits => _significantDigits;
  set significantDigits(int x) {
    _significantDigits = x;
    significantDigitsInUse = true;
  }

  bool significantDigitsInUse = false;

  /// For percent and permille, what are we multiplying by in order to
  /// get the printed value, e.g. 100 for percent.
  int get _multiplier => _internalMultiplier;
  set _multiplier(int x) {
    _internalMultiplier = x;
    _multiplierDigits = (log(_multiplier) / LN10).round();
  }

  int _internalMultiplier = 1;

  /// How many digits are there in the [_multiplier].
  int _multiplierDigits = 0;

  /// Stores the pattern used to create this format. This isn't used, but
  /// is helpful in debugging.
  String _pattern;

  /// The locale in which we print numbers.
  final String _locale;

  /// Caches the symbols used for our locale.
  NumberSymbols _symbols;

  /// The name of the currency to print, in ISO 4217 form.
  String currencyName;

  /// The symbol to be used when formatting this as currency.
  ///
  /// For example, "$", "US$", or "€".
  String _currencySymbol;

  /// The symbol to be used when formatting this as currency.
  ///
  /// For example, "$", "US$", or "€".
  String get currencySymbol => _currencySymbol ?? currencyName;

  /// The number of decimal places to use when formatting.
  ///
  /// If this is not explicitly specified in the constructor, then for
  /// currencies we use the default value for the currency if the name is given,
  /// otherwise we use the value from the pattern for the locale.
  ///
  /// So, for example,
  ///      new NumberFormat.currency(name: 'USD', decimalDigits: 7)
  /// will format with 7 decimal digits, because that's what we asked for. But
  ///       new NumberFormat.currency(locale: 'en_US', name: 'JPY')
  /// will format with zero, because that's the default for JPY, and the
  /// currency's default takes priority over the locale's default.
  ///       new NumberFormat.currency(locale: 'en_US')
  /// will format with two, which is the default for that locale.
  ///
  int get decimalDigits => _decimalDigits;

  int _decimalDigits;

  /// For currencies, the default number of decimal places to use in
  /// formatting. Defaults to two for non-currencies or currencies where it's
  /// not specified.
  int get _defaultDecimalDigits =>
      currencyFractionDigits[currencyName.toUpperCase()] ??
      currencyFractionDigits['DEFAULT'];

  /// If we have a currencyName, use the decimal digits for that currency,
  /// unless we've explicitly specified some other number.
  bool get _overridesDecimalDigits => decimalDigits != null || _isForCurrency;

  /// Transient internal state in which to build up the result of the format
  /// operation. We can have this be just an instance variable because Dart is
  /// single-threaded and unless we do an asynchronous operation in the process
  /// of formatting then there will only ever be one number being formatted
  /// at a time. In languages with threads we'd need to pass this on the stack.
  final StringBuffer _buffer = new StringBuffer();

  /// Create a number format that prints using [newPattern] as it applies in
  /// [locale].
  factory NumberFormat([String newPattern, String locale]) =>
      new NumberFormat._forPattern(locale, (x) => newPattern);

  /// Create a number format that prints as DECIMAL_PATTERN.
  NumberFormat.decimalPattern([String locale])
      : this._forPattern(locale, (x) => x.DECIMAL_PATTERN);

  /// Create a number format that prints as PERCENT_PATTERN.
  NumberFormat.percentPattern([String locale])
      : this._forPattern(locale, (x) => x.PERCENT_PATTERN);

  /// Create a number format that prints as SCIENTIFIC_PATTERN.
  NumberFormat.scientificPattern([String locale])
      : this._forPattern(locale, (x) => x.SCIENTIFIC_PATTERN);

  /// A regular expression to validate currency names are exactly three
  /// alphabetic characters.
  static final _checkCurrencyName = new RegExp(r'^[a-zA-Z]{3}$');

  /// Create a number format that prints as CURRENCY_PATTERN. (Deprecated:
  /// prefer NumberFormat.currency)
  ///
  /// If provided,
  /// use [nameOrSymbol] in place of the default currency name. e.g.
  ///        var eurosInCurrentLocale = new NumberFormat
  ///            .currencyPattern(Intl.defaultLocale, "€");
  @Deprecated("Use NumberFormat.currency")
  factory NumberFormat.currencyPattern(
      [String locale, String currencyNameOrSymbol]) {
    // If it looks like an iso4217 name, pass as name, otherwise as symbol.
    if (currencyNameOrSymbol != null &&
        _checkCurrencyName.hasMatch(currencyNameOrSymbol)) {
      return new NumberFormat.currency(
          locale: locale, name: currencyNameOrSymbol);
    } else {
      return new NumberFormat.currency(
          locale: locale, symbol: currencyNameOrSymbol);
    }
  }

  /// Create a [NumberFormat] that formats using the locale's CURRENCY_PATTERN.
  ///
  /// If [locale] is not specified, it will use the current default locale.
  ///
  /// If [name] is specified, the currency with that ISO 4217 name will be used.
  /// Otherwise we will use the default currency name for the current locale. If
  /// no [symbol] is specified, we will use the currency name in the formatted
  /// result. e.g.
  ///      var f = new NumberFormat.currency(locale: 'en_US', name: 'EUR')
  /// will format currency like "EUR1.23". If we did not specify the name, it
  /// would format like "USD1.23".
  ///
  /// If [symbol] is used, then that symbol will be used in formatting instead
  /// of the name. e.g.
  ///      var eurosInCurrentLocale = new NumberFormat.currency(symbol: "€");
  /// will format like "€1.23". Otherwise it will use the currency name.
  /// If this is not explicitly specified in the constructor, then for
  /// currencies we use the default value for the currency if the name is given,
  ///  otherwise we use the value from the pattern for the locale.
  ///
  /// If [decimalDigits] is specified, numbers will format with that many digits
  /// after the decimal place. If it's not, they will use the default for the
  /// currency in [name], and the default currency for [locale] if the currency
  /// name is not specified. e.g.
  ///       new NumberFormat.currency(name: 'USD', decimalDigits: 7)
  /// will format with 7 decimal digits, because that's what we asked for. But
  ///       new NumberFormat.currency(locale: 'en_US', name: 'JPY')
  /// will format with zero, because that's the default for JPY, and the
  /// currency's default takes priority over the locale's default.
  ///       new NumberFormat.currency(locale: 'en_US')
  /// will format with two, which is the default for that locale.
  // TODO(alanknight): Should we allow decimalDigits on other numbers.
  NumberFormat.currency(
      {String locale, String name, String symbol, int decimalDigits})
      : this._forPattern(locale, (x) => x.CURRENCY_PATTERN,
            name: name,
            currencySymbol: symbol,
            decimalDigits: decimalDigits,
            isForCurrency: true);

  /// Creates a [NumberFormat] for currencies, using the simple symbol for the
  /// currency if one is available (e.g. $, €), so it should only be used if the
  /// short currency symbol will be unambiguous.
  ///
  /// If [locale] is not specified, it will use the current default locale.
  ///
  /// If [name] is specified, the currency with that ISO 4217 name will be used.
  /// Otherwise we will use the default currency name for the current locale. We
  /// will assume that the symbol for this is well known in the locale and
  /// unambiguous. If you format CAD in an en_US locale using this format it
  /// will display as "$", which may be confusing to the user.
  ///
  /// If [decimalDigits] is specified, numbers will format with that many digits
  /// after the decimal place. If it's not, they will use the default for the
  /// currency in [name], and the default currency for [locale] if the currency
  /// name is not specified. e.g.
  ///       new NumberFormat.simpleCurrency(name: 'USD', decimalDigits: 7)
  /// will format with 7 decimal digits, because that's what we asked for. But
  ///       new NumberFormat.simpleCurrency(locale: 'en_US', name: 'JPY')
  /// will format with zero, because that's the default for JPY, and the
  /// currency's default takes priority over the locale's default.
  ///       new NumberFormat.simpleCurrency(locale: 'en_US')
  /// will format with two, which is the default for that locale.
  factory NumberFormat.simpleCurrency(
      {String locale, String name, int decimalDigits}) {
    return new NumberFormat._forPattern(locale, (x) => x.CURRENCY_PATTERN,
        name: name,
        computeCurrencySymbol: (format) =>
            _simpleCurrencySymbols[format.currencyName] ?? format.currencyName,
        decimalDigits: decimalDigits,
        isForCurrency: true);
  }

  /// Returns the simple currency symbol for given currency code, or
  /// [currencyCode] if no simple symbol is listed.
  ///
  /// The simple currency symbol is generally short, and the same or related to
  /// what is used in countries having the currency as an official symbol. It
  /// may be a symbol character, or may have letters, or both. It may be
  /// different according to the locale: for example, for an Arabic locale it
  /// may consist of Arabic letters, but for a French locale consist of Latin
  /// letters. It will not be unique: for example, "$" can appear for both USD
  /// and CAD.
  ///
  /// (The current implementation is the same for all locales, but this is
  /// temporary and callers shouldn't rely on it.)
  String simpleCurrencySymbol(String currencyCode) =>
      _simpleCurrencySymbols[currencyCode] ?? currencyCode;

  /// A map from currency names to the simple name/symbol.
  ///
  /// The simple currency symbol is generally short, and the same or related to
  /// what is used in countries having the currency as an official symbol. It
  /// may be a symbol character, or may have letters, or both. It may be
  /// different according to the locale: for example, for an Arabic locale it
  /// may consist of Arabic letters, but for a French locale consist of Latin
  /// letters. It will not be unique: for example, "$" can appear for both USD
  /// and CAD.
  ///
  /// (The current implementation is the same for all locales, but this is
  /// temporary and callers shouldn't rely on it.)
  static Map<String, String> _simpleCurrencySymbols = {
    "AFN": "Af.",
    "TOP": r"T$",
    "MGA": "Ar",
    "THB": "\u0e3f",
    "PAB": "B/.",
    "ETB": "Birr",
    "VEF": "Bs",
    "BOB": "Bs",
    "GHS": "GHS",
    "CRC": "\u20a1",
    "NIO": r"C$",
    "GMD": "GMD",
    "MKD": "din",
    "BHD": "din",
    "DZD": "din",
    "IQD": "din",
    "JOD": "din",
    "KWD": "din",
    "LYD": "din",
    "RSD": "din",
    "TND": "din",
    "AED": "dh",
    "MAD": "dh",
    "STD": "Db",
    "BSD": r"$",
    "FJD": r"$",
    "GYD": r"$",
    "KYD": r"$",
    "LRD": r"$",
    "SBD": r"$",
    "SRD": r"$",
    "AUD": r"$",
    "BBD": r"$",
    "BMD": r"$",
    "BND": r"$",
    "BZD": r"$",
    "CAD": r"$",
    "HKD": r"$",
    "JMD": r"$",
    "NAD": r"$",
    "NZD": r"$",
    "SGD": r"$",
    "TTD": r"$",
    "TWD": r"NT$",
    "USD": r"$",
    "XCD": r"$",
    "VND": "\u20ab",
    "AMD": "Dram",
    "CVE": "CVE",
    "EUR": "\u20ac",
    "AWG": "Afl.",
    "HUF": "Ft",
    "BIF": "FBu",
    "CDF": "FrCD",
    "CHF": "CHF",
    "DJF": "Fdj",
    "GNF": "FG",
    "RWF": "RF",
    "XOF": "CFA",
    "XPF": "FCFP",
    "KMF": "CF",
    "XAF": "FCFA",
    "HTG": "HTG",
    "PYG": "Gs",
    "UAH": "\u20b4",
    "PGK": "PGK",
    "LAK": "\u20ad",
    "CZK": "K\u010d",
    "SEK": "kr",
    "ISK": "kr",
    "DKK": "kr",
    "NOK": "kr",
    "HRK": "kn",
    "MWK": "MWK",
    "ZMK": "ZWK",
    "AOA": "Kz",
    "MMK": "K",
    "GEL": "GEL",
    "LVL": "Ls",
    "ALL": "Lek",
    "HNL": "L",
    "SLL": "SLL",
    "MDL": "MDL",
    "RON": "RON",
    "BGN": "lev",
    "SZL": "SZL",
    "TRY": "TL",
    "LTL": "Lt",
    "LSL": "LSL",
    "AZN": "man.",
    "BAM": "KM",
    "MZN": "MTn",
    "NGN": "\u20a6",
    "ERN": "Nfk",
    "BTN": "Nu.",
    "MRO": "MRO",
    "MOP": "MOP",
    "CUP": r"$",
    "CUC": r"$",
    "ARS": r"$",
    "CLF": "UF",
    "CLP": r"$",
    "COP": r"$",
    "DOP": r"$",
    "MXN": r"$",
    "PHP": "\u20b1",
    "UYU": r"$",
    "FKP": "£",
    "GIP": "£",
    "SHP": "£",
    "EGP": "E£",
    "LBP": "L£",
    "SDG": "SDG",
    "SSP": "SSP",
    "GBP": "£",
    "SYP": "£",
    "BWP": "P",
    "GTQ": "Q",
    "ZAR": "R",
    "BRL": r"R$",
    "OMR": "Rial",
    "QAR": "Rial",
    "YER": "Rial",
    "IRR": "Rial",
    "KHR": "Riel",
    "MYR": "RM",
    "SAR": "Rial",
    "BYR": "BYR",
    "RUB": "руб.",
    "MUR": "Rs",
    "SCR": "SCR",
    "LKR": "Rs",
    "NPR": "Rs",
    "INR": "\u20b9",
    "PKR": "Rs",
    "IDR": "Rp",
    "ILS": "\u20aa",
    "KES": "Ksh",
    "SOS": "SOS",
    "TZS": "TSh",
    "UGX": "UGX",
    "PEN": "S/.",
    "KGS": "KGS",
    "UZS": "so\u02bcm",
    "TJS": "Som",
    "BDT": "\u09f3",
    "WST": "WST",
    "KZT": "\u20b8",
    "MNT": "\u20ae",
    "VUV": "VUV",
    "KPW": "\u20a9",
    "KRW": "\u20a9",
    "JPY": "¥",
    "CNY": "¥",
    "PLN": "z\u0142",
    "MVR": "Rf",
    "NLG": "NAf",
    "ZMW": "ZK",
    "ANG": "ƒ",
    "TMT": "TMT",
  };

  /// Create a number format that prints in a pattern we get from
  /// the [getPattern] function using the locale [locale].
  ///
  /// The [currencySymbol] can either be specified directly, or we can pass a
  /// function [computeCurrencySymbol] that will compute it later, given other
  /// information, typically the verified locale.
  NumberFormat._forPattern(String locale, _PatternGetter getPattern,
      {String name,
      String currencySymbol,
      String computeCurrencySymbol(NumberFormat),
      int decimalDigits,
      bool isForCurrency: false})
      : _locale = Intl.verifiedLocale(locale, localeExists),
        _isForCurrency = isForCurrency {
    this._currencySymbol = currencySymbol;
    this._decimalDigits = decimalDigits;
    _symbols = numberFormatSymbols[_locale];
    _localeZero = _symbols.ZERO_DIGIT.codeUnitAt(0);
    _zeroOffset = _localeZero - _zero;
    _negativePrefix = _symbols.MINUS_SIGN;
    currencyName = name ?? _symbols.DEF_CURRENCY_CODE;
    if (this._currencySymbol == null && computeCurrencySymbol != null) {
      this._currencySymbol = computeCurrencySymbol(this);
    }
    _setPattern(getPattern(_symbols));
  }

  /// A number format for compact representations, e.g. "1.2M" instead
  /// of "1,200,000".
  factory NumberFormat.compact({String locale}) {
    return new _CompactNumberFormat(
        locale: locale,
        formatType: _CompactFormatType.COMPACT_DECIMAL_SHORT_PATTERN);
  }

  /// A number format for "long" compact representations, e.g. "1.2 million"
  /// instead of of "1,200,000".
  factory NumberFormat.compactLong({String locale}) {
    return new _CompactNumberFormat(
        locale: locale,
        formatType: _CompactFormatType.COMPACT_DECIMAL_LONG_PATTERN);
  }

  /// A number format for compact currency representations, e.g. "$1.2M" instead
  /// of "$1,200,000", and which will automatically determine a currency symbol
  /// based on the currency name or the locale. See
  /// [NumberFormat.simpleCurrency].
  factory NumberFormat.compactSimpleCurrency({String locale, String name}) {
    return new _CompactNumberFormat(
        locale: locale,
        formatType: _CompactFormatType.COMPACT_DECIMAL_SHORT_CURRENCY_PATTERN,
        name: name,
        getPattern: (symbols) => symbols.CURRENCY_PATTERN,
        computeCurrencySymbol: (format) =>
            _simpleCurrencySymbols[format.currencyName] ?? format.currencyName,
        isForCurrency: true);
  }

  /// A number format for compact currency representations, e.g. "$1.2M" instead
  /// of "$1,200,000".
  factory NumberFormat.compactCurrency(
      {String locale, String name, String symbol, int decimalDigits}) {
    return new _CompactNumberFormat(
        locale: locale,
        formatType: _CompactFormatType.COMPACT_DECIMAL_SHORT_CURRENCY_PATTERN,
        name: name,
        getPattern: (symbols) => symbols.CURRENCY_PATTERN,
        currencySymbol: symbol,
        decimalDigits: decimalDigits,
        isForCurrency: true);
  }

  /// Return the locale code in which we operate, e.g. 'en_US' or 'pt'.
  String get locale => _locale;

  /// Return true if the locale exists, or if it is null. The null case
  /// is interpreted to mean that we use the default locale.
  static bool localeExists(localeName) {
    if (localeName == null) return false;
    return numberFormatSymbols.containsKey(localeName);
  }

  /// Return the symbols which are used in our locale. Cache them to avoid
  /// repeated lookup.
  NumberSymbols get symbols => _symbols;

  /// Format [number] according to our pattern and return the formatted string.
  String format(number) {
    if (_isNaN(number)) return symbols.NAN;
    if (_isInfinite(number)) return "${_signPrefix(number)}${symbols.INFINITY}";

    _add(_signPrefix(number));
    _formatNumber(number.abs());
    _add(_signSuffix(number));

    var result = _buffer.toString();
    _buffer.clear();
    return result;
  }

  /// Parse the number represented by the string. If it's not
  /// parseable, throws a [FormatException].
  num parse(String text) => new _NumberParser(this, text).value;

  /// Format the main part of the number in the form dictated by the pattern.
  void _formatNumber(number) {
    if (_useExponentialNotation) {
      _formatExponential(number);
    } else {
      _formatFixed(number);
    }
  }

  /// Format the number in exponential notation.
  void _formatExponential(num number) {
    if (number == 0.0) {
      _formatFixed(number);
      _formatExponent(0);
      return;
    }

    var exponent = (log(number) / LN10).floor();
    var mantissa = number / pow(10.0, exponent);

    if (maximumIntegerDigits > 1 &&
        maximumIntegerDigits > minimumIntegerDigits) {
      // A repeating range is defined; adjust to it as follows.
      // If repeat == 3, we have 6,5,4=>3; 3,2,1=>0; 0,-1,-2=>-3;
      // -3,-4,-5=>-6, etc. This takes into account that the
      // exponent we have here is off by one from what we expect;
      // it is for the format 0.MMMMMx10^n.
      while ((exponent % maximumIntegerDigits) != 0) {
        mantissa *= 10;
        exponent--;
      }
    } else {
      // No repeating range is defined, use minimum integer digits.
      if (minimumIntegerDigits < 1) {
        exponent++;
        mantissa /= 10;
      } else {
        exponent -= minimumIntegerDigits - 1;
        mantissa *= pow(10, minimumIntegerDigits - 1);
      }
    }
    _formatFixed(mantissa);
    _formatExponent(exponent);
  }

  /// Format the exponent portion, e.g. in "1.3e-5" the "e-5".
  void _formatExponent(num exponent) {
    _add(symbols.EXP_SYMBOL);
    if (exponent < 0) {
      exponent = -exponent;
      _add(symbols.MINUS_SIGN);
    } else if (_useSignForPositiveExponent) {
      _add(symbols.PLUS_SIGN);
    }
    _pad(minimumExponentDigits, exponent.toString());
  }

  /// Used to test if we have exceeded Javascript integer limits.
  final _maxInt = pow(2, 52);

  /// Helpers to check numbers that don't conform to the [num] interface,
  /// e.g. Int64
  _isInfinite(number) => number is num ? number.isInfinite : false;
  _isNaN(number) => number is num ? number.isNaN : false;

  /// Helper to get the floor of a number which might not be num. This should
  /// only ever be called with an argument which is positive, or whose abs()
  ///  is negative. The second case is the maximum negative value on a
  ///  fixed-length integer. Since they are integers, they are also their own
  ///  floor.
  _floor(number) {
    if (number.isNegative && !(number.abs().isNegative)) {
      throw new ArgumentError(
          "Internal error: expected positive number, got $number");
    }
    return (number is num) ? number.floor() : number ~/ 1;
  }

  /// Helper to round a number which might not be num.
  _round(number) {
    if (number is num) {
      if (number.isInfinite) {
        return _maxInt;
      } else {
        return number.round();
      }
    } else if (number.remainder(1) == 0) {
      // Not a normal number, but int-like, e.g. Int64
      return number;
    } else {
      // TODO(alanknight): Do this more efficiently. If IntX  had floor and round we could avoid this.
      var basic = _floor(number);
      var fraction = (number - basic).toDouble().round();
      return fraction == 0 ? number : number + fraction;
    }
  }

  // Return the number of digits left of the decimal place in [number].
  static int numberOfIntegerDigits(number) {
    var simpleNumber = number.toDouble().abs();
    // It's unfortunate that we have to do this, but we get precision errors
    // that affect the result if we use logs, e.g. 1000000
    if (simpleNumber < 10) return 1;
    if (simpleNumber < 100) return 2;
    if (simpleNumber < 1000) return 3;
    if (simpleNumber < 10000) return 4;
    if (simpleNumber < 100000) return 5;
    if (simpleNumber < 1000000) return 6;
    if (simpleNumber < 10000000) return 7;
    if (simpleNumber < 100000000) return 8;
    if (simpleNumber < 1000000000) return 9;
    if (simpleNumber < 10000000000) return 10;
    if (simpleNumber < 100000000000) return 11;
    if (simpleNumber < 1000000000000) return 12;
    if (simpleNumber < 10000000000000) return 13;
    if (simpleNumber < 100000000000000) return 14;
    if (simpleNumber < 1000000000000000) return 15;
    if (simpleNumber < 10000000000000000) return 16;
    // We're past the point where being off by one on the number of digits
    // will affect the pattern, so now we can use logs.
    return max(1, (log(simpleNumber) / LN10).ceil());
  }

  int _fractionDigitsAfter(int remainingSignificantDigits) =>
      max(0, remainingSignificantDigits);

  /// Format the basic number portion, including the fractional digits.
  void _formatFixed(number) {
    var integerPart;
    int fractionPart;
    int extraIntegerDigits;
    var fractionDigits = maximumFractionDigits;

    var power = 0;
    var digitMultiplier;

    if (_isInfinite(number)) {
      integerPart = number.toInt();
      extraIntegerDigits = 0;
      fractionPart = 0;
    } else {
      // We have three possible pieces. First, the basic integer part. If this
      // is a percent or permille, the additional 2 or 3 digits. Finally the
      // fractional part.
      // We avoid multiplying the number because it might overflow if we have
      // a fixed-size integer type, so we extract each of the three as an
      // integer pieces.
      integerPart = _floor(number);
      var fraction = number - integerPart;

      /// If we have significant digits, recalculate the number of fraction
      /// digits based on that.
      if (significantDigitsInUse) {
        var integerLength = numberOfIntegerDigits(integerPart);
        var remainingSignificantDigits =
            significantDigits - _multiplierDigits - integerLength;
        fractionDigits = _fractionDigitsAfter(remainingSignificantDigits);
        if (remainingSignificantDigits < 0) {
          // We may have to round.
          var divideBy = pow(10, integerLength - significantDigits);
          integerPart = (integerPart / divideBy).round() * divideBy;
        }
      }
      power = pow(10, fractionDigits);
      digitMultiplier = power * _multiplier;

      // Multiply out to the number of decimal places and the percent, then
      // round. For fixed-size integer types this should always be zero, so
      // multiplying is OK.
      var remainingDigits = _round(fraction * digitMultiplier).toInt();
      // However, in rounding we may overflow into the main digits.
      if (remainingDigits >= digitMultiplier) {
        integerPart++;
        remainingDigits -= digitMultiplier;
      }
      // Separate out the extra integer parts from the fraction part.
      extraIntegerDigits = remainingDigits ~/ power;
      fractionPart = remainingDigits % power;
    }

    var integerDigits = _integerDigits(integerPart, extraIntegerDigits);
    var digitLength = integerDigits.length;
    var fractionPresent =
        fractionDigits > 0 && (minimumFractionDigits > 0 || fractionPart > 0);

    if (_hasIntegerDigits(integerDigits)) {
      // Add the padding digits to the regular digits so that we get grouping.
      var padding = '0' * (minimumIntegerDigits - digitLength);
      integerDigits = "$padding$integerDigits";
      digitLength = integerDigits.length;
      for (var i = 0; i < digitLength; i++) {
        _addDigit(integerDigits.codeUnitAt(i));
        _group(digitLength, i);
      }
    } else if (!fractionPresent) {
      // If neither fraction nor integer part exists, just print zero.
      _addZero();
    }

    _decimalSeparator(fractionPresent);
    _formatFractionPart((fractionPart + power).toString());
  }

  /// Compute the raw integer digits which will then be printed with
  /// grouping and translated to localized digits.
  String _integerDigits(integerPart, extraIntegerDigits) {
    // If the int part is larger than 2^52 and we're on Javascript (so it's
    // really a float) it will lose precision, so pad out the rest of it
    // with zeros. Check for Javascript by seeing if an integer is double.
    var paddingDigits = '';
    if (1 is double && integerPart is num && integerPart > _maxInt) {
      var howManyDigitsTooBig = (log(integerPart) / LN10).ceil() - 16;
      var divisor = pow(10, howManyDigitsTooBig).round();
      paddingDigits = '0' * howManyDigitsTooBig.toInt();
      integerPart = (integerPart / divisor).truncate();
    }

    var extra = extraIntegerDigits == 0 ? '' : extraIntegerDigits.toString();
    var intDigits = _mainIntegerDigits(integerPart);
    var paddedExtra =
        intDigits.isEmpty ? extra : extra.padLeft(_multiplierDigits, '0');
    return "${intDigits}${paddedExtra}${paddingDigits}";
  }

  /// The digit string of the integer part. This is the empty string if the
  /// integer part is zero and otherwise is the toString() of the integer
  /// part, stripping off any minus sign.
  String _mainIntegerDigits(integer) {
    if (integer == 0) return '';
    var digits = integer.toString();
    if (significantDigitsInUse && digits.length > significantDigits) {
      digits = digits.substring(0, significantDigits) +
          ''.padLeft(digits.length - significantDigits, '0');
    }
    // If we have a fixed-length int representation, it can have a negative
    // number whose negation is also negative, e.g. 2^-63 in 64-bit.
    // Remove the minus sign.
    return digits.startsWith('-') ? digits.substring(1) : digits;
  }

  /// Format the part after the decimal place in a fixed point number.
  void _formatFractionPart(String fractionPart) {
    var fractionLength = fractionPart.length;
    while (fractionPart.codeUnitAt(fractionLength - 1) == _zero &&
        fractionLength > minimumFractionDigits + 1) {
      fractionLength--;
    }
    for (var i = 1; i < fractionLength; i++) {
      _addDigit(fractionPart.codeUnitAt(i));
    }
  }

  /// Print the decimal separator if appropriate.
  void _decimalSeparator(bool fractionPresent) {
    if (_decimalSeparatorAlwaysShown || fractionPresent) {
      _add(symbols.DECIMAL_SEP);
    }
  }

  /// Return true if we have a main integer part which is printable, either
  /// because we have digits left of the decimal point (this may include digits
  /// which have been moved left because of percent or permille formatting),
  /// or because the minimum number of printable digits is greater than 1.
  bool _hasIntegerDigits(String digits) =>
      digits.isNotEmpty || minimumIntegerDigits > 0;

  /// A group of methods that provide support for writing digits and other
  /// required characters into [_buffer] easily.
  void _add(String x) {
    _buffer.write(x);
  }

  void _addZero() {
    _buffer.write(symbols.ZERO_DIGIT);
  }

  void _addDigit(int x) {
    _buffer.writeCharCode(x + _zeroOffset);
  }

  void _pad(int numberOfDigits, String basic) {
    if (_zeroOffset == 0) {
      _buffer.write(basic.padLeft(numberOfDigits, '0'));
    } else {
      _slowPad(numberOfDigits, basic);
    }
  }

  /// Print padding up to [numberOfDigits] above what's included in [basic].
  void _slowPad(int numberOfDigits, String basic) {
    for (var i = 0; i < numberOfDigits - basic.length; i++) {
      _add(symbols.ZERO_DIGIT);
    }
    for (int i = 0; i < basic.length; i++) {
      _addDigit(basic.codeUnitAt(i));
    }
  }

  /// We are printing the digits of the number from left to right. We may need
  /// to print a thousands separator or other grouping character as appropriate
  /// to the locale. So we find how many places we are from the end of the number
  /// by subtracting our current [position] from the [totalLength] and printing
  /// the separator character every [_groupingSize] digits, with the final
  /// grouping possibly being of a different size, [_finalGroupingSize].
  void _group(int totalLength, int position) {
    var distanceFromEnd = totalLength - position;
    if (distanceFromEnd <= 1 || _groupingSize <= 0) return;
    if (distanceFromEnd == _finalGroupingSize + 1) {
      _add(symbols.GROUP_SEP);
    } else if ((distanceFromEnd > _finalGroupingSize) &&
        (distanceFromEnd - _finalGroupingSize) % _groupingSize == 1) {
      _add(symbols.GROUP_SEP);
    }
  }

  /// The code point for the character '0'.
  static const _zero = 48;

  /// The code point for the locale's zero digit.
  ///
  ///  Initialized when the locale is set.
  int _localeZero = 0;

  /// The difference between our zero and '0'.
  ///
  /// In other words, a constant _localeZero - _zero. Initialized when
  /// the locale is set.
  int _zeroOffset = 0;

  /// Returns the prefix for [x] based on whether it's positive or negative.
  /// In en_US this would be '' and '-' respectively.
  String _signPrefix(x) => x.isNegative ? _negativePrefix : _positivePrefix;

  /// Returns the suffix for [x] based on wether it's positive or negative.
  /// In en_US there are no suffixes for positive or negative.
  String _signSuffix(x) => x.isNegative ? _negativeSuffix : _positiveSuffix;

  void _setPattern(String newPattern) {
    if (newPattern == null) return;
    // Make spaces non-breaking
    _pattern = newPattern.replaceAll(' ', '\u00a0');
    var parser = new _NumberFormatParser(
        this, newPattern, currencySymbol, decimalDigits);
    parser.parse();
    if (_overridesDecimalDigits) {
      _decimalDigits ??= _defaultDecimalDigits;
      minimumFractionDigits = _decimalDigits;
      maximumFractionDigits = _decimalDigits;
    }
  }

  /// Explicitly turn off any grouping (e.g. by thousands) in this format.
  ///
  /// This is used in compact number formatting, where we
  /// omit the normal grouping. Best to know what you're doing if you call it.
  void turnOffGrouping() {
    _groupingSize = 0;
    _finalGroupingSize = 0;
  }

  String toString() => "NumberFormat($_locale, $_pattern)";
}

///  A one-time object for parsing a particular numeric string. One-time here
/// means an instance can only parse one string. This is implemented by
/// transforming from a locale-specific format to one that the system can parse,
/// then calls the system parsing methods on it.
class _NumberParser {
  /// The format for which we are parsing.
  final NumberFormat format;

  /// The text we are parsing.
  final String text;

  /// What we use to iterate over the input text.
  final _Stream input;

  /// The result of parsing [text] according to [format]. Automatically
  /// populated in the constructor.
  num value;

  /// The symbols used by our format.
  NumberSymbols get symbols => format.symbols;

  /// Where we accumulate the normalized representation of the number.
  final StringBuffer _normalized = new StringBuffer();

  /// Did we see something that indicates this is, or at least might be,
  /// a positive number.
  bool gotPositive = false;

  /// Did we see something that indicates this is, or at least might be,
  /// a negative number.
  bool gotNegative = false;

  /// Did we see the required positive suffix at the end. Should
  /// match [gotPositive].
  bool gotPositiveSuffix = false;

  /// Did we see the required negative suffix at the end. Should
  /// match [gotNegative].
  bool gotNegativeSuffix = false;

  /// Should we stop parsing before hitting the end of the string.
  bool done = false;

  /// Have we already skipped over any required prefixes.
  bool prefixesSkipped = false;

  /// If the number is percent or permill, what do we divide by at the end.
  int scale = 1;

  String get _positivePrefix => format._positivePrefix;
  String get _negativePrefix => format._negativePrefix;
  String get _positiveSuffix => format._positiveSuffix;
  String get _negativeSuffix => format._negativeSuffix;
  int get _zero => NumberFormat._zero;
  int get _localeZero => format._localeZero;

  ///  Create a new [_NumberParser] on which we can call parse().
  _NumberParser(this.format, text)
      : this.text = text,
        this.input = new _Stream(text) {
    scale = format._internalMultiplier;
    value = parse();
  }

  ///  The strings we might replace with functions that return the replacement
  /// values. They are functions because we might need to check something
  /// in the context. Note that the ordering is important here. For example,
  /// [symbols.PERCENT] might be " %", and we must handle that before we
  /// look at an individual space.
  Map<String, Function> get replacements =>
      _replacements ??= _initializeReplacements();

  Map<String, Function> _replacements;

  Map<String, Function> _initializeReplacements() => {
        symbols.DECIMAL_SEP: () => '.',
        symbols.EXP_SYMBOL: () => 'E',
        symbols.GROUP_SEP: handleSpace,
        symbols.PERCENT: () {
          scale = _NumberFormatParser._PERCENT_SCALE;
          return '';
        },
        symbols.PERMILL: () {
          scale = _NumberFormatParser._PER_MILLE_SCALE;
          return '';
        },
        ' ': handleSpace,
        '\u00a0': handleSpace,
        '+': () => '+',
        '-': () => '-',
      };

  invalidFormat() =>
      throw new FormatException("Invalid number: ${input.contents}");

  /// Replace a space in the number with the normalized form. If space is not
  /// a significant character (normally grouping) then it's just invalid. If it
  /// is the grouping character, then it's only valid if it's followed by a
  /// digit. e.g. '$12 345.00'
  handleSpace() =>
      groupingIsNotASpaceOrElseItIsSpaceFollowedByADigit ? '' : invalidFormat();

  /// Determine if a space is a valid character in the number. See
  /// [handleSpace].
  bool get groupingIsNotASpaceOrElseItIsSpaceFollowedByADigit {
    if (symbols.GROUP_SEP != '\u00a0' || symbols.GROUP_SEP != ' ') return true;
    var peeked = input.peek(symbols.GROUP_SEP.length + 1);
    return asDigit(peeked[peeked.length - 1]) != null;
  }

  /// Turn [char] into a number representing a digit, or null if it doesn't
  /// represent a digit in this locale.
  int asDigit(String char) {
    var charCode = char.codeUnitAt(0);
    var digitValue = charCode - _localeZero;
    if (digitValue >= 0 && digitValue < 10) {
      return digitValue;
    } else {
      return null;
    }
  }

  /// Check to see if the input begins with either the positive or negative
  /// prefixes. Set the [gotPositive] and [gotNegative] variables accordingly.
  void checkPrefixes({bool skip: false}) {
    bool checkPrefix(String prefix) =>
        prefix.isNotEmpty && input.startsWith(prefix);

    // TODO(alanknight): There's a faint possibility of a bug here where
    // a positive prefix is followed by a negative prefix that's also a valid
    // part of the number, but that seems very unlikely.
    if (checkPrefix(_positivePrefix)) gotPositive = true;
    if (checkPrefix(_negativePrefix)) gotNegative = true;

    // The positive prefix might be a substring of the negative, in
    // which case both would match.
    if (gotPositive && gotNegative) {
      if (_positivePrefix.length > _negativePrefix.length) {
        gotNegative = false;
      } else if (_negativePrefix.length > _positivePrefix.length) {
        gotPositive = false;
      }
    }
    if (skip) {
      if (gotPositive) input.read(_positivePrefix.length);
      if (gotNegative) input.read(_negativePrefix.length);
    }
  }

  /// If the rest of our input is either the positive or negative suffix,
  /// set [gotPositiveSuffix] or [gotNegativeSuffix] accordingly.
  void checkSuffixes() {
    var remainder = input.rest();
    if (remainder == _positiveSuffix) gotPositiveSuffix = true;
    if (remainder == _negativeSuffix) gotNegativeSuffix = true;
  }

  /// We've encountered a character that's not a digit. Go through our
  /// replacement rules looking for how to handle it. If we see something
  /// that's not a digit and doesn't have a replacement, then we're done
  /// and the number is probably invalid.
  void processNonDigit() {
    // It might just be a prefix that we haven't skipped. We don't want to
    // skip them initially because they might also be semantically meaningful,
    // e.g. leading %. So we allow them through the loop, but only once.
    var foundAnInterpretation = false;
    if (input.index == 0 && !prefixesSkipped) {
      prefixesSkipped = true;
      checkPrefixes(skip: true);
      foundAnInterpretation = true;
    }

    for (var key in replacements.keys) {
      if (input.startsWith(key)) {
        _normalized.write(replacements[key]());
        input.read(key.length);
        return;
      }
    }
    // We haven't found either of these things, this seems invalid.
    if (!foundAnInterpretation) {
      done = true;
    }
  }

  /// Parse [text] and return the resulting number. Throws [FormatException]
  /// if we can't parse it.
  num parse() {
    if (text == symbols.NAN) return double.NAN;
    if (text == "$_positivePrefix${symbols.INFINITY}$_positiveSuffix") {
      return double.INFINITY;
    }
    if (text == "$_negativePrefix${symbols.INFINITY}$_negativeSuffix") {
      return double.NEGATIVE_INFINITY;
    }

    checkPrefixes();
    var parsed = parseNumber(input);

    if (gotPositive && !gotPositiveSuffix) invalidNumber();
    if (gotNegative && !gotNegativeSuffix) invalidNumber();
    if (!input.atEnd()) invalidNumber();

    return parsed;
  }

  /// The number is invalid, throw a [FormatException].
  void invalidNumber() =>
      throw new FormatException("Invalid Number: ${input.contents}");

  /// Parse the number portion of the input, i.e. not any prefixes or suffixes,
  /// and assuming NaN and Infinity are already handled.
  num parseNumber(_Stream input) {
    if (gotNegative) {
      _normalized.write('-');
    }
    while (!done && !input.atEnd()) {
      int digit = asDigit(input.peek());
      if (digit != null) {
        _normalized.writeCharCode(_zero + digit);
        input.next();
      } else {
        processNonDigit();
      }
      checkSuffixes();
    }

    var normalizedText = _normalized.toString();
    num parsed = int.parse(normalizedText, onError: (message) => null);
    if (parsed == null) parsed = double.parse(normalizedText);
    return parsed / scale;
  }
}

/// Private class that parses the numeric formatting pattern and sets the
/// variables in [format] to appropriate values. Instances of this are
/// transient and store parsing state in instance variables, so can only be used
/// to parse a single pattern.
class _NumberFormatParser {
  /// The special characters in the pattern language. All others are treated
  /// as literals.
  static const _PATTERN_SEPARATOR = ';';
  static const _QUOTE = "'";
  static const _PATTERN_DIGIT = '#';
  static const _PATTERN_ZERO_DIGIT = '0';
  static const _PATTERN_GROUPING_SEPARATOR = ',';
  static const _PATTERN_DECIMAL_SEPARATOR = '.';
  static const _PATTERN_CURRENCY_SIGN = '\u00A4';
  static const _PATTERN_PER_MILLE = '\u2030';
  static const _PER_MILLE_SCALE = 1000;
  static const _PATTERN_PERCENT = '%';
  static const _PERCENT_SCALE = 100;
  static const _PATTERN_EXPONENT = 'E';
  static const _PATTERN_PLUS = '+';

  /// The format whose state we are setting.
  final NumberFormat format;

  /// The pattern we are parsing.
  final _StringIterator pattern;

  /// We can be passed a specific currency symbol, regardless of the locale.
  String currencySymbol;

  /// We can be given a specific number of decimal places, overriding the
  /// default.
  final int decimalDigits;

  /// Create a new [_NumberFormatParser] for a particular [NumberFormat] and
  /// [input] pattern.
  _NumberFormatParser(
      this.format, input, this.currencySymbol, this.decimalDigits)
      : pattern = _iterator(input) {
    pattern.moveNext();
  }

  /// The [NumberSymbols] for the locale in which our [format] prints.
  NumberSymbols get symbols => format.symbols;

  /// Parse the input pattern and set the values.
  void parse() {
    format._positivePrefix = _parseAffix();
    var trunk = _parseTrunk();
    format._positiveSuffix = _parseAffix();
    // If we have separate positive and negative patterns, now parse the
    // the negative version.
    if (pattern.current == _NumberFormatParser._PATTERN_SEPARATOR) {
      pattern.moveNext();
      format._negativePrefix = _parseAffix();
      // Skip over the negative trunk, verifying that it's identical to the
      // positive trunk.
      for (var each in _iterable(trunk)) {
        if (pattern.current != each && pattern.current != null) {
          throw new FormatException(
              "Positive and negative trunks must be the same");
        }
        pattern.moveNext();
      }
      format._negativeSuffix = _parseAffix();
    } else {
      // If no negative affix is specified, they share the same positive affix.
      format._negativePrefix = format._negativePrefix + format._positivePrefix;
      format._negativeSuffix = format._positiveSuffix + format._negativeSuffix;
    }
  }

  /// Variable used in parsing prefixes and suffixes to keep track of
  /// whether or not we are in a quoted region.
  bool inQuote = false;

  /// Parse a prefix or suffix and return the prefix/suffix string. Note that
  /// this also may modify the state of [format].
  String _parseAffix() {
    var affix = new StringBuffer();
    inQuote = false;
    while (parseCharacterAffix(affix) && pattern.moveNext());
    return affix.toString();
  }

  /// Parse an individual character as part of a prefix or suffix.  Return true
  /// if we should continue to look for more affix characters, and false if
  /// we have reached the end.
  bool parseCharacterAffix(StringBuffer affix) {
    var ch = pattern.current;
    if (ch == null) return false;
    if (ch == _QUOTE) {
      if (pattern.peek == _QUOTE) {
        pattern.moveNext();
        affix.write(_QUOTE); // 'don''t'
      } else {
        inQuote = !inQuote;
      }
      return true;
    }

    if (inQuote) {
      affix.write(ch);
    } else {
      switch (ch) {
        case _PATTERN_DIGIT:
        case _PATTERN_ZERO_DIGIT:
        case _PATTERN_GROUPING_SEPARATOR:
        case _PATTERN_DECIMAL_SEPARATOR:
        case _PATTERN_SEPARATOR:
          return false;
        case _PATTERN_CURRENCY_SIGN:
          // TODO(alanknight): Handle the local/global/portable currency signs
          affix.write(currencySymbol);
          break;
        case _PATTERN_PERCENT:
          if (format._multiplier != 1 && format._multiplier != _PERCENT_SCALE) {
            throw new FormatException('Too many percent/permill');
          }
          format._multiplier = _PERCENT_SCALE;
          affix.write(symbols.PERCENT);
          break;
        case _PATTERN_PER_MILLE:
          if (format._multiplier != 1 &&
              format._multiplier != _PER_MILLE_SCALE) {
            throw new FormatException('Too many percent/permill');
          }
          format._multiplier = _PER_MILLE_SCALE;
          affix.write(symbols.PERMILL);
          break;
        default:
          affix.write(ch);
      }
    }
    return true;
  }

  /// Variables used in [_parseTrunk] and [parseTrunkCharacter].
  var decimalPos = -1;
  var digitLeftCount = 0;
  var zeroDigitCount = 0;
  var digitRightCount = 0;
  var groupingCount = -1;

  /// Parse the "trunk" portion of the pattern, the piece that doesn't include
  /// positive or negative prefixes or suffixes.
  String _parseTrunk() {
    var loop = true;
    var trunk = new StringBuffer();
    while (pattern.current != null && loop) {
      loop = parseTrunkCharacter(trunk);
    }

    if (zeroDigitCount == 0 && digitLeftCount > 0 && decimalPos >= 0) {
      // Handle '###.###' and '###.' and '.###'
      // Handle '.###'
      var n = decimalPos == 0 ? 1 : decimalPos;
      digitRightCount = digitLeftCount - n;
      digitLeftCount = n - 1;
      zeroDigitCount = 1;
    }

    // Do syntax checking on the digits.
    if (decimalPos < 0 && digitRightCount > 0 ||
        decimalPos >= 0 &&
            (decimalPos < digitLeftCount ||
                decimalPos > digitLeftCount + zeroDigitCount) ||
        groupingCount == 0) {
      throw new FormatException('Malformed pattern "${pattern.input}"');
    }
    var totalDigits = digitLeftCount + zeroDigitCount + digitRightCount;

    format.maximumFractionDigits =
        decimalPos >= 0 ? totalDigits - decimalPos : 0;
    if (decimalPos >= 0) {
      format.minimumFractionDigits =
          digitLeftCount + zeroDigitCount - decimalPos;
      if (format.minimumFractionDigits < 0) {
        format.minimumFractionDigits = 0;
      }
    }

    // The effectiveDecimalPos is the position the decimal is at or would be at
    // if there is no decimal. Note that if decimalPos<0, then digitTotalCount
    // == digitLeftCount + zeroDigitCount.
    var effectiveDecimalPos = decimalPos >= 0 ? decimalPos : totalDigits;
    format.minimumIntegerDigits = effectiveDecimalPos - digitLeftCount;
    if (format._useExponentialNotation) {
      format.maximumIntegerDigits =
          digitLeftCount + format.minimumIntegerDigits;

      // In exponential display, we need to at least show something.
      if (format.maximumFractionDigits == 0 &&
          format.minimumIntegerDigits == 0) {
        format.minimumIntegerDigits = 1;
      }
    }

    format._finalGroupingSize = max(0, groupingCount);
    if (!format._groupingSizeSetExplicitly) {
      format._groupingSize = format._finalGroupingSize;
    }
    format._decimalSeparatorAlwaysShown =
        decimalPos == 0 || decimalPos == totalDigits;

    return trunk.toString();
  }

  /// Parse an individual character of the trunk. Return true if we should
  /// continue to look for additional trunk characters or false if we have
  /// reached the end.
  bool parseTrunkCharacter(trunk) {
    var ch = pattern.current;
    switch (ch) {
      case _PATTERN_DIGIT:
        if (zeroDigitCount > 0) {
          digitRightCount++;
        } else {
          digitLeftCount++;
        }
        if (groupingCount >= 0 && decimalPos < 0) {
          groupingCount++;
        }
        break;
      case _PATTERN_ZERO_DIGIT:
        if (digitRightCount > 0) {
          throw new FormatException(
              'Unexpected "0" in pattern "' + pattern.input + '"');
        }
        zeroDigitCount++;
        if (groupingCount >= 0 && decimalPos < 0) {
          groupingCount++;
        }
        break;
      case _PATTERN_GROUPING_SEPARATOR:
        if (groupingCount > 0) {
          format._groupingSizeSetExplicitly = true;
          format._groupingSize = groupingCount;
        }
        groupingCount = 0;
        break;
      case _PATTERN_DECIMAL_SEPARATOR:
        if (decimalPos >= 0) {
          throw new FormatException(
              'Multiple decimal separators in pattern "$pattern"');
        }
        decimalPos = digitLeftCount + zeroDigitCount + digitRightCount;
        break;
      case _PATTERN_EXPONENT:
        trunk.write(ch);
        if (format._useExponentialNotation) {
          throw new FormatException(
              'Multiple exponential symbols in pattern "$pattern"');
        }
        format._useExponentialNotation = true;
        format.minimumExponentDigits = 0;

        // exponent pattern can have a optional '+'.
        pattern.moveNext();
        var nextChar = pattern.current;
        if (nextChar == _PATTERN_PLUS) {
          trunk.write(pattern.current);
          pattern.moveNext();
          format._useSignForPositiveExponent = true;
        }

        // Use lookahead to parse out the exponential part
        // of the pattern, then jump into phase 2.
        while (pattern.current == _PATTERN_ZERO_DIGIT) {
          trunk.write(pattern.current);
          pattern.moveNext();
          format.minimumExponentDigits++;
        }

        if ((digitLeftCount + zeroDigitCount) < 1 ||
            format.minimumExponentDigits < 1) {
          throw new FormatException('Malformed exponential pattern "$pattern"');
        }
        return false;
      default:
        return false;
    }
    trunk.write(ch);
    pattern.moveNext();
    return true;
  }
}

/// Returns an [Iterable] on the string as a list of substrings.
Iterable _iterable(String s) => new _StringIterable(s);

/// Return an iterator on the string as a list of substrings.
Iterator<String> _iterator(String s) => new _StringIterator(s);

// TODO(nweiz): remove this when issue 3780 is fixed.
/// Provides an Iterable that wraps [_iterator] so it can be used in a `for`
/// loop.
class _StringIterable extends IterableBase<String> {
  final Iterator<String> iterator;

  _StringIterable(String s) : iterator = _iterator(s);
}

/// Provides an iterator over a string as a list of substrings, and also
/// gives us a lookahead of one via the [peek] method.
class _StringIterator implements Iterator<String> {
  final String input;
  int nextIndex = 0;
  String _current = null;

  _StringIterator(input) : input = _validate(input);

  String get current => _current;

  bool moveNext() {
    if (nextIndex >= input.length) {
      _current = null;
      return false;
    }
    _current = input[nextIndex++];
    return true;
  }

  String get peek => nextIndex >= input.length ? null : input[nextIndex];

  Iterator<String> get iterator => this;

  static String _validate(input) {
    if (input is! String) throw new ArgumentError(input);
    return input;
  }
}

/// Used primarily for currency formatting, this number-like class stores
/// millionths of a currency unit, typically as an Int64.
///
/// It supports no operations other than being used for Intl number formatting.
abstract class MicroMoney {
  factory MicroMoney(micros) => new _MicroMoney(micros);
}

/// Used primarily for currency formatting, this stores millionths of a
/// currency unit, typically as an Int64.
///
/// This private class provides the operations needed by the formatting code.
class _MicroMoney implements MicroMoney {
  var _micros;
  _MicroMoney(this._micros);
  static const _multiplier = 1000000;

  get _integerPart => _micros ~/ _multiplier;
  int get _fractionPart => (this - _integerPart)._micros.toInt().abs();

  bool get isNegative => _micros.isNegative;

  _MicroMoney abs() => isNegative ? new _MicroMoney(_micros.abs()) : this;

  // Note that if this is done in a general way there's a risk of integer
  // overflow on JS when multiplying out the [other] parameter, which may be
  // an Int64. In formatting we only ever subtract out our own integer part.
  _MicroMoney operator -(other) {
    if (other is _MicroMoney) return new _MicroMoney(_micros - other._micros);
    return new _MicroMoney(_micros - (other * _multiplier));
  }

  _MicroMoney operator +(other) {
    if (other is _MicroMoney) return new _MicroMoney(_micros + other._micros);
    return new _MicroMoney(_micros + (other * _multiplier));
  }

  _MicroMoney operator ~/(divisor) {
    if (divisor is! int) {
      throw new ArgumentError.value(
          divisor, 'divisor', '_MicroMoney ~/ only supports int arguments.');
    }
    return new _MicroMoney((_integerPart ~/ divisor) * _multiplier);
  }

  _MicroMoney operator *(other) {
    if (other is! int) {
      throw new ArgumentError.value(
          other, 'other', '_MicroMoney * only supports int arguments.');
    }
    return new _MicroMoney(
        (_integerPart * other) * _multiplier + (_fractionPart * other));
  }

  /// Note that this only really supports remainder from an int,
  /// not division by another MicroMoney
  _MicroMoney remainder(other) {
    if (other is! int) {
      throw new ArgumentError.value(
          other, 'other', '_MicroMoney.remainder only supports int arguments.');
    }
    return new _MicroMoney(_micros.remainder(other * _multiplier));
  }

  double toDouble() => _micros.toDouble() / _multiplier;

  int toInt() => _integerPart.toInt();

  String toString() {
    var beforeDecimal = _integerPart.toString();
    var decimalPart = '';
    var fractionPart = _fractionPart;
    if (fractionPart != 0) {
      decimalPart = '.' + fractionPart.toString();
    }
    return '$beforeDecimal$decimalPart';
  }
}
