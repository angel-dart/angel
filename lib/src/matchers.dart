import 'package:matcher/matcher.dart';

final RegExp _alphaDash = new RegExp(r'^[A-Za-z0-9_-]+$');
final RegExp _alphaNum = new RegExp(r'^[A-Za-z0-9]+$');
final RegExp _email = new RegExp(
    r"^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$");

/// Asserts that a `String` is alphanumeric, but also lets it contain dashes or underscores.
final Matcher isAlphaDash = predicate(
    (value) => value is String && _alphaDash.hasMatch(value),
    'alphanumeric (dashes and underscores are allowed) ');

/// Asserts that a `String` is alphanumeric, but also lets it contain dashes or underscores.
final Matcher isAlphaNum = predicate(
    (value) => value is String && _alphaNum.hasMatch(value), 'alphanumeric ');

/// Asserts that a value either equals `true` or `false`.
final Matcher isBool = predicate((value) => value is bool, 'a bool ');

///  Asserts that a `String` complies to the RFC 5322 e-mail standard.
final Matcher isEmail = predicate(
    (value) => value is String && _email.hasMatch(value), 'a valid e-mail ');

/// Asserts that a value is an `int`.
final Matcher isInt = predicate((value) => value is int, 'an integer ');

/// Asserts that a value is a `num`.
final Matcher isNum = predicate((value) => value is num, 'a number ');

/// Asserts that a value is a `String`.
final Matcher isString = predicate((value) => value is String, 'a String ');
