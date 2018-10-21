import 'dart:convert';
import 'dart:io';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:http/http.dart' as http;
import 'package:matcher/matcher.dart';

/// Expects a response to be a JSON representation of an `AngelHttpException`.
///
/// You can optionally check for a matching [message], [statusCode] and [errors].
Matcher isAngelHttpException(
        {String message, int statusCode, Iterable<String> errors: const []}) =>
    new _IsAngelHttpException(
        message: message, statusCode: statusCode, errors: errors);

/// Expects a given response, when parsed as JSON,
/// to equal a desired value.
Matcher isJson(value) => new _IsJson(value);

/// Expects a response to have the given content type, whether a `String` or [ContentType].
Matcher hasContentType(contentType) => new _HasContentType(contentType);

/// Expects a response to have the given body.
///
/// If `true` is passed as the value (default), then this matcher will simply assert
/// that the response has a non-empty body.
///
/// If value is a `List<int>`, then it will be matched against `res.bodyBytes`.
/// Otherwise, the string value will be matched against `res.body`.
Matcher hasBody([value]) => new _HasBody(value ?? true);

/// Expects a response to have a header named [key] which contains [value]. [value] can be a `String`, or a List of `String`s.
///
/// If `value` is true (default), then this matcher will simply assert that the header is present.
Matcher hasHeader(String key, [value]) => new _HasHeader(key, value ?? true);

/// Expects a response to have the given status code.
Matcher hasStatus(int status) => new _HasStatus(status);

/// Expects a response to have a JSON body that is a `Map` and satisfies the given [validator] schema.
Matcher hasValidBody(Validator validator) => new _HasValidBody(validator);

class _IsJson extends Matcher {
  var value;

  _IsJson(this.value);

  @override
  Description describe(Description description) {
    return description.add('equals the desired JSON response: $value');
  }

  @override
  bool matches(item, Map matchState) =>
      item is http.Response &&
      equals(value).matches(json.decode(item.body), matchState);
}

class _HasBody extends Matcher {
  final body;

  _HasBody(this.body);

  @override
  Description describe(Description description) =>
      description.add('has body $body');

  @override
  bool matches(item, Map matchState) {
    if (item is http.Response) {
      if (body == true) return isNotEmpty.matches(item.bodyBytes, matchState);
      if (body is List<int>)
        return equals(body).matches(item.bodyBytes, matchState);
      else
        return equals(body.toString()).matches(item.body, matchState);
    } else {
      return false;
    }
  }
}

class _HasContentType extends Matcher {
  var contentType;

  _HasContentType(this.contentType);

  @override
  Description describe(Description description) {
    var str = contentType is ContentType
        ? ((contentType as ContentType).value)
        : contentType.toString();
    return description.add('has content type ' + str);
  }

  @override
  bool matches(item, Map matchState) {
    if (item is http.Response) {
      if (!item.headers.containsKey('content-type')) return false;

      if (contentType is ContentType) {
        var compare = ContentType.parse(item.headers['content-type']);
        return equals(contentType.mimeType)
            .matches(compare.mimeType, matchState);
      } else {
        return equals(contentType.toString())
            .matches(item.headers['content-type'], matchState);
      }
    } else {
      return false;
    }
  }
}

class _HasHeader extends Matcher {
  final String key;
  final value;

  _HasHeader(this.key, this.value);

  @override
  Description describe(Description description) {
    if (value == true)
      return description.add('contains header $key');
    else
      return description.add('contains header $key with value(s) $value');
  }

  @override
  bool matches(item, Map matchState) {
    if (item is http.Response) {
      if (value == true) {
        return contains(key.toLowerCase())
            .matches(item.headers.keys, matchState);
      } else {
        if (!item.headers.containsKey(key.toLowerCase())) return false;
        Iterable v = value is Iterable ? (value as Iterable) : [value];
        return v
            .map((x) => x.toString())
            .every(item.headers[key.toLowerCase()].split(',').contains);
      }
    } else {
      return false;
    }
  }
}

class _HasStatus extends Matcher {
  int status;

  _HasStatus(this.status);

  @override
  Description describe(Description description) {
    return description.add('has status code $status');
  }

  @override
  bool matches(item, Map matchState) =>
      item is http.Response &&
      equals(status).matches(item.statusCode, matchState);
}

class _HasValidBody extends Matcher {
  final Validator validator;

  _HasValidBody(this.validator);

  @override
  Description describe(Description description) =>
      description.add('matches validation schema ${validator.rules}');

  @override
  bool matches(item, Map matchState) {
    if (item is http.Response) {
      final jsons = json.decode(item.body);
      if (jsons is! Map) return false;
      return validator.matches(jsons, matchState);
    } else {
      return false;
    }
  }
}

class _IsAngelHttpException extends Matcher {
  String message;
  int statusCode;
  final List<String> errors = [];

  _IsAngelHttpException(
      {this.message, this.statusCode, Iterable<String> errors: const []}) {
    this.errors.addAll(errors ?? []);
  }

  @override
  Description describe(Description description) {
    if (message?.isNotEmpty != true && statusCode == null && errors.isEmpty)
      return description.add('is an Angel HTTP Exception');
    else {
      var buf = new StringBuffer('is an Angel HTTP Exception with');

      if (statusCode != null) buf.write(' status code $statusCode');

      if (message?.isNotEmpty == true) {
        if (statusCode != null && errors.isNotEmpty)
          buf.write(',');
        else if (statusCode != null && errors.isEmpty) buf.write(' and');
        buf.write(' message "$message"');
      }

      if (errors.isNotEmpty) {
        if (statusCode != null || message?.isNotEmpty == true)
          buf.write(' and errors $errors');
        else
          buf.write(' errors $errors');
      }

      return description.add(buf.toString());
    }
  }

  @override
  bool matches(item, Map matchState) {
    if (item is http.Response) {
      final jsons = json.decode(item.body);

      if (jsons is Map && jsons['isError'] == true) {
        var exc = new AngelHttpException.fromMap(jsons);
        print(exc.toJson());

        if (message?.isNotEmpty != true && statusCode == null && errors.isEmpty)
          return true;
        else {
          if (statusCode != null) if (!equals(statusCode)
              .matches(exc.statusCode, matchState)) return false;

          if (message?.isNotEmpty == true) if (!equals(message)
              .matches(exc.message, matchState)) return false;

          if (errors.isNotEmpty) {
            if (!errors
                .every((err) => contains(err).matches(exc.errors, matchState)))
              return false;
          }

          return true;
        }
      } else
        return false;
    } else {
      return false;
    }
  }
}
