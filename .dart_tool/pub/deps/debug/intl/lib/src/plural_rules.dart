// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides locale-specific plural rules. Based on pluralrules.js from Closure.
///
/// Each function does the calculation for one or more locales. These are done in terms of
/// various values used by the CLDR syntax and defined by UTS #35
/// http://unicode.org/reports/tr35/tr35-numbers.html#Plural_rules_syntax
///
/// * n - absolute value of the source number (integer and decimals).
/// * i	- integer digits of n.
/// * v	- number of visible fraction digits in n, with trailing zeros.
/// * w	- number of visible fraction digits in n, without trailing zeros.
/// * f	- visible fractional digits in n, with trailing zeros.
/// * t	- visible fractional digits in n, without trailing zeros.
library plural_rules;

typedef PluralCase PluralRule();

/// The possible cases used in a plural rule.
enum PluralCase { ZERO, ONE, TWO, FEW, MANY, OTHER }

/// The default rule in case we don't have anything more specific for a locale.
PluralCase _default_rule() => OTHER;

/// This must be called before evaluating a new rule, because we're using
/// library-global state to both keep the rules terse and minimize space.
startRuleEvaluation(int howMany) {
  _n = howMany;
}

/// The number whose [PluralCase] we are trying to find.
///
// This is library-global state, along with the other variables. This allows us
// to avoid calculating parameters that the functions don't need and also
// not introduce a subclass per locale or have instance tear-offs which
// we can't cache. This is fine as long as these methods aren't async, which
// they should never be.
int _n;

/// The integer part of [_n] - since we only support integers, it's the same as
/// [_n].
int get _i => _n;
int opt_precision; // Not currently used.

/// Number of visible fraction digits. Always zero since we only support int.
int get _v => 0;

/// Number of visible fraction digits without trailing zeros. Always zero
/// since we only support int.
//int get _w => 0;

/// The visible fraction digits in n, with trailing zeros. Always zero since
/// we only support int.
int get _f => 0;

/// The visible fraction digits in n, without trailing zeros. Always zero since
/// we only support int.
int get _t => 0;

PluralCase get ZERO => PluralCase.ZERO;
PluralCase get ONE => PluralCase.ONE;
PluralCase get TWO => PluralCase.TWO;
PluralCase get FEW => PluralCase.FEW;
PluralCase get MANY => PluralCase.MANY;
PluralCase get OTHER => PluralCase.OTHER;

PluralCase _fil_rule() {
  if (_v == 0 && (_i == 1 || _i == 2 || _i == 3) ||
      _v == 0 && _i % 10 != 4 && _i % 10 != 6 && _i % 10 != 9 ||
      _v != 0 && _f % 10 != 4 && _f % 10 != 6 && _f % 10 != 9) {
    return ONE;
  }
  return OTHER;
}

PluralCase _pt_PT_rule() {
  if (_n == 1 && _v == 0) {
    return ONE;
  }
  return OTHER;
}

PluralCase _br_rule() {
  if (_n % 10 == 1 && _n % 100 != 11 && _n % 100 != 71 && _n % 100 != 91) {
    return ONE;
  }
  if (_n % 10 == 2 && _n % 100 != 12 && _n % 100 != 72 && _n % 100 != 92) {
    return TWO;
  }
  if ((_n % 10 >= 3 && _n % 10 <= 4 || _n % 10 == 9) &&
      (_n % 100 < 10 || _n % 100 > 19) &&
      (_n % 100 < 70 || _n % 100 > 79) &&
      (_n % 100 < 90 || _n % 100 > 99)) {
    return FEW;
  }
  if (_n != 0 && _n % 1000000 == 0) {
    return MANY;
  }
  return OTHER;
}

PluralCase _sr_rule() {
  if (_v == 0 && _i % 10 == 1 && _i % 100 != 11 ||
      _f % 10 == 1 && _f % 100 != 11) {
    return ONE;
  }
  if (_v == 0 &&
          _i % 10 >= 2 &&
          _i % 10 <= 4 &&
          (_i % 100 < 12 || _i % 100 > 14) ||
      _f % 10 >= 2 && _f % 10 <= 4 && (_f % 100 < 12 || _f % 100 > 14)) {
    return FEW;
  }
  return OTHER;
}

PluralCase _ro_rule() {
  if (_i == 1 && _v == 0) {
    return ONE;
  }
  if (_v != 0 || _n == 0 || _n != 1 && _n % 100 >= 1 && _n % 100 <= 19) {
    return FEW;
  }
  return OTHER;
}

PluralCase _hi_rule() {
  if (_i == 0 || _n == 1) {
    return ONE;
  }
  return OTHER;
}

PluralCase _fr_rule() {
  if (_i == 0 || _i == 1) {
    return ONE;
  }
  return OTHER;
}

PluralCase _cs_rule() {
  if (_i == 1 && _v == 0) {
    return ONE;
  }
  if (_i >= 2 && _i <= 4 && _v == 0) {
    return FEW;
  }
  if (_v != 0) {
    return MANY;
  }
  return OTHER;
}

PluralCase _pl_rule() {
  if (_i == 1 && _v == 0) {
    return ONE;
  }
  if (_v == 0 &&
      _i % 10 >= 2 &&
      _i % 10 <= 4 &&
      (_i % 100 < 12 || _i % 100 > 14)) {
    return FEW;
  }
  if (_v == 0 && _i != 1 && _i % 10 >= 0 && _i % 10 <= 1 ||
      _v == 0 && _i % 10 >= 5 && _i % 10 <= 9 ||
      _v == 0 && _i % 100 >= 12 && _i % 100 <= 14) {
    return MANY;
  }
  return OTHER;
}

PluralCase _lv_rule() {
  if (_n % 10 == 0 ||
      _n % 100 >= 11 && _n % 100 <= 19 ||
      _v == 2 && _f % 100 >= 11 && _f % 100 <= 19) {
    return ZERO;
  }
  if (_n % 10 == 1 && _n % 100 != 11 ||
      _v == 2 && _f % 10 == 1 && _f % 100 != 11 ||
      _v != 2 && _f % 10 == 1) {
    return ONE;
  }
  return OTHER;
}

PluralCase _he_rule() {
  if (_i == 1 && _v == 0) {
    return ONE;
  }
  if (_i == 2 && _v == 0) {
    return TWO;
  }
  if (_v == 0 && (_n < 0 || _n > 10) && _n % 10 == 0) {
    return MANY;
  }
  return OTHER;
}

PluralCase _mt_rule() {
  if (_n == 1) {
    return ONE;
  }
  if (_n == 0 || _n % 100 >= 2 && _n % 100 <= 10) {
    return FEW;
  }
  if (_n % 100 >= 11 && _n % 100 <= 19) {
    return MANY;
  }
  return OTHER;
}

PluralCase _si_rule() {
  if ((_n == 0 || _n == 1) || _i == 0 && _f == 1) {
    return ONE;
  }
  return OTHER;
}

PluralCase _cy_rule() {
  if (_n == 0) {
    return ZERO;
  }
  if (_n == 1) {
    return ONE;
  }
  if (_n == 2) {
    return TWO;
  }
  if (_n == 3) {
    return FEW;
  }
  if (_n == 6) {
    return MANY;
  }
  return OTHER;
}

PluralCase _da_rule() {
  if (_n == 1 || _t != 0 && (_i == 0 || _i == 1)) {
    return ONE;
  }
  return OTHER;
}

PluralCase _ru_rule() {
  if (_v == 0 && _i % 10 == 1 && _i % 100 != 11) {
    return ONE;
  }
  if (_v == 0 &&
      _i % 10 >= 2 &&
      _i % 10 <= 4 &&
      (_i % 100 < 12 || _i % 100 > 14)) {
    return FEW;
  }
  if (_v == 0 && _i % 10 == 0 ||
      _v == 0 && _i % 10 >= 5 && _i % 10 <= 9 ||
      _v == 0 && _i % 100 >= 11 && _i % 100 <= 14) {
    return MANY;
  }
  return OTHER;
}

PluralCase _be_rule() {
  if (_n % 10 == 1 && _n % 100 != 11) {
    return ONE;
  }
  if (_n % 10 >= 2 && _n % 10 <= 4 && (_n % 100 < 12 || _n % 100 > 14)) {
    return FEW;
  }
  if (_n % 10 == 0 ||
      _n % 10 >= 5 && _n % 10 <= 9 ||
      _n % 100 >= 11 && _n % 100 <= 14) {
    return MANY;
  }
  return OTHER;
}

PluralCase _mk_rule() {
  if (_v == 0 && _i % 10 == 1 || _f % 10 == 1) {
    return ONE;
  }
  return OTHER;
}

PluralCase _ga_rule() {
  if (_n == 1) {
    return ONE;
  }
  if (_n == 2) {
    return TWO;
  }
  if (_n >= 3 && _n <= 6) {
    return FEW;
  }
  if (_n >= 7 && _n <= 10) {
    return MANY;
  }
  return OTHER;
}

PluralCase _pt_rule() {
  if (_n >= 0 && _n <= 2 && _n != 2) {
    return ONE;
  }
  return OTHER;
}

PluralCase _es_rule() {
  if (_n == 1) {
    return ONE;
  }
  return OTHER;
}

PluralCase _is_rule() {
  if (_t == 0 && _i % 10 == 1 && _i % 100 != 11 || _t != 0) {
    return ONE;
  }
  return OTHER;
}

PluralCase _ar_rule() {
  if (_n == 0) {
    return ZERO;
  }
  if (_n == 1) {
    return ONE;
  }
  if (_n == 2) {
    return TWO;
  }
  if (_n % 100 >= 3 && _n % 100 <= 10) {
    return FEW;
  }
  if (_n % 100 >= 11 && _n % 100 <= 99) {
    return MANY;
  }
  return OTHER;
}

PluralCase _sl_rule() {
  if (_v == 0 && _i % 100 == 1) {
    return ONE;
  }
  if (_v == 0 && _i % 100 == 2) {
    return TWO;
  }
  if (_v == 0 && _i % 100 >= 3 && _i % 100 <= 4 || _v != 0) {
    return FEW;
  }
  return OTHER;
}

PluralCase _lt_rule() {
  if (_n % 10 == 1 && (_n % 100 < 11 || _n % 100 > 19)) {
    return ONE;
  }
  if (_n % 10 >= 2 && _n % 10 <= 9 && (_n % 100 < 11 || _n % 100 > 19)) {
    return FEW;
  }
  if (_f != 0) {
    return MANY;
  }
  return OTHER;
}

PluralCase _en_rule() {
  if (_i == 1 && _v == 0) {
    return ONE;
  }
  return OTHER;
}

PluralCase _ak_rule() {
  if (_n >= 0 && _n <= 1) {
    return ONE;
  }
  return OTHER;
}

/// Selected Plural rules by locale.
final Map pluralRules = {
  'af': _es_rule,
  'am': _hi_rule,
  'ar': _ar_rule,
  'az': _es_rule,
  'be': _be_rule,
  'bg': _es_rule,
  'bn': _hi_rule,
  'br': _br_rule,
  'bs': _sr_rule,
  'ca': _en_rule,
  'chr': _es_rule,
  'cs': _cs_rule,
  'cy': _cy_rule,
  'da': _da_rule,
  'de': _en_rule,
  'de_AT': _en_rule,
  'de_CH': _en_rule,
  'el': _es_rule,
  'en': _en_rule,
  'en_AU': _en_rule,
  'en_CA': _en_rule,
  'en_GB': _en_rule,
  'en_IE': _en_rule,
  'en_IN': _en_rule,
  'en_SG': _en_rule,
  'en_US': _en_rule,
  'en_ZA': _en_rule,
  'es': _es_rule,
  'es_419': _es_rule,
  'es_ES': _es_rule,
  'es_MX': _es_rule,
  'es_US': _es_rule,
  'et': _en_rule,
  'eu': _es_rule,
  'fa': _hi_rule,
  'fi': _en_rule,
  'fil': _fil_rule,
  'fr': _fr_rule,
  'fr_CA': _fr_rule,
  'ga': _ga_rule,
  'gl': _en_rule,
  'gsw': _es_rule,
  'gu': _hi_rule,
  'haw': _es_rule,
  'he': _he_rule,
  'hi': _hi_rule,
  'hr': _sr_rule,
  'hu': _es_rule,
  'hy': _fr_rule,
  'id': _default_rule,
  'in': _default_rule,
  'is': _is_rule,
  'it': _en_rule,
  'iw': _he_rule,
  'ja': _default_rule,
  'ka': _es_rule,
  'kk': _es_rule,
  'km': _default_rule,
  'kn': _hi_rule,
  'ko': _default_rule,
  'ky': _es_rule,
  'ln': _ak_rule,
  'lo': _default_rule,
  'lt': _lt_rule,
  'lv': _lv_rule,
  'mk': _mk_rule,
  'ml': _es_rule,
  'mn': _es_rule,
  'mo': _ro_rule,
  'mr': _hi_rule,
  'ms': _default_rule,
  'mt': _mt_rule,
  'my': _default_rule,
  'nb': _es_rule,
  'ne': _es_rule,
  'nl': _en_rule,
  'no': _es_rule,
  'no_NO': _es_rule,
  'or': _es_rule,
  'pa': _ak_rule,
  'pl': _pl_rule,
  'pt': _pt_rule,
  'pt_BR': _pt_rule,
  'pt_PT': _pt_PT_rule,
  'ro': _ro_rule,
  'ru': _ru_rule,
  'sh': _sr_rule,
  'si': _si_rule,
  'sk': _cs_rule,
  'sl': _sl_rule,
  'sq': _es_rule,
  'sr': _sr_rule,
  'sr_Latn': _sr_rule,
  'sv': _en_rule,
  'sw': _en_rule,
  'ta': _es_rule,
  'te': _es_rule,
  'th': _default_rule,
  'tl': _fil_rule,
  'tr': _es_rule,
  'uk': _ru_rule,
  'ur': _en_rule,
  'uz': _es_rule,
  'vi': _default_rule,
  'zh': _default_rule,
  'zh_CN': _default_rule,
  'zh_HK': _default_rule,
  'zh_TW': _default_rule,
  'zu': _hi_rule,
  'default': _default_rule
};

/// Do we have plural rules specific to [locale]
bool localeHasPluralRules(String locale) => pluralRules.containsKey(locale);
