import 'dart-ext:angel_security_native';

/// Using `libinjection`, determines whether a string contains
/// a SQL injection.
bool isSqli(String text) native "Angel_Security_IsSqli";
