part of 'native.dart';

List _isSqli(String text) native "Angel_Security_IsSqli";

/// Using `libinjection`, determines whether a string contains
/// a SQL injection.
LibInjectionScore sqlInjectionScore(String text) {
  var result = _isSqli(text);
  return LibInjectionScore(result[0] as bool, result[1] as String);
}

class LibInjectionScore {
  final bool isInjection;
  final String signature;

  LibInjectionScore(this.isInjection, [this.signature]);
}
