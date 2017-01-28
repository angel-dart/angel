import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:matcher/matcher.dart';

/// Expects a given response, when parsed as JSON,
/// to equal a desired value.
Matcher isJson(value) => new _IsJson(value);

/// Expects a response to have the given status code.
Matcher hasStatus(int status) => new _HasStatus(status);

class _IsJson extends Matcher {
  var value;

  _IsJson(this.value);

  @override
  Description describe(Description description) {
    return description.add('should equal the desired JSON response: $value');
  }

  @override
  bool matches(http.Response item, Map matchState) =>
      equals(value).matches(JSON.decode(item.body), matchState);
}

class _HasStatus extends Matcher {
  int status;

  _HasStatus(this.status);

  @override
  Description describe(Description description) {
    return description.add('should have status code $status');
  }

  @override
  bool matches(http.Response item, Map matchState) =>
      equals(status).matches(item.statusCode, matchState);
}
