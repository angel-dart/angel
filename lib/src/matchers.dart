import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:matcher/matcher.dart';

/// Expects a given response, when parsed as JSON,
/// to equal a desired value.