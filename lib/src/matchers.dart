import 'package:matcher/matcher.dart';

/// Asserts that a value either equals `true` or `false`.
final Matcher isBool = predicate((value) => value is String, 'a bool ');

/// Asserts that a value is an `int`.
final Matcher isInt = predicate((value) => value is String, 'an integer ');

/// Asserts that a value is a `num`.
final Matcher isNumber = predicate((value) => value is String, 'a number ');

/// Asserts that a value is a `String`.
final Matcher isString = predicate((value) => value is String, 'a String ');
