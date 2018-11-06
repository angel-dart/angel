/// Support for using `angel_validate` with the Angel Framework.
library angel_validate.server;

import 'dart:async';

import 'package:angel_framework/angel_framework.dart';
import 'src/async.dart';
import 'angel_validate.dart';
export 'src/async.dart';
export 'angel_validate.dart';

/// Auto-parses numbers in `req.body`.
RequestHandler autoParseBody(List<String> fields) {
  return (RequestContext req, res) async {
    var body = await req.parseBody();
    body.addAll(autoParse(body, fields));
    return true;
  };
}

/// Auto-parses numbers in `req.query`.
RequestHandler autoParseQuery(List<String> fields) {
  return (RequestContext req, res) async {
    var query = new Map<String, dynamic>.from(await req.parseQuery());
    (await req.parseQuery()).addAll(autoParse(query, fields));
    return true;
  };
}

/// Filters unwanted data out of `req.body`.
RequestHandler filterBody(Iterable<String> only) {
  return (RequestContext req, res) async {
    var body = await req.parseBody();
    var filtered = filter(body, only);
    body
      ..clear()
      ..addAll(filtered);
    return true;
  };
}

/// Filters unwanted data out of `req.query`.
RequestHandler filterQuery(Iterable<String> only) {
  return (RequestContext req, res) async {
    var query = await req.parseQuery();
    var filtered = filter(query, only);
    (await req.parseQuery())
      ..clear()
      ..addAll(filtered);
    return true;
  };
}

/// Validates the data in `req.body`, and sets the body to
/// filtered data before continuing the response.
RequestHandler validate(Validator validator,
    {String errorMessage: 'Invalid data.'}) {
  return (RequestContext req, res) async {
    var body = await req.parseBody();
    var result =
        await asyncApplyValidator(validator, body, req.app);

    if (result.errors.isNotEmpty) {
      throw new AngelHttpException.badRequest(
          message: errorMessage, errors: result.errors);
    }

    body
      ..clear()
      ..addAll(result.data);

    return true;
  };
}

/// Validates the data in `req.query`, and sets the query to
/// filtered data before continuing the response.
RequestHandler validateQuery(Validator validator,
    {String errorMessage: 'Invalid data.'}) {
  return (RequestContext req, res) async {
    var query = await req.parseQuery();
    var result =
        await asyncApplyValidator(validator, query, req.app);

    if (result.errors.isNotEmpty) {
      throw new AngelHttpException.badRequest(
          message: errorMessage, errors: result.errors);
    }

    (await req.parseQuery())
      ..clear()
      ..addAll(result.data);

    return true;
  };
}

/// Validates the data in `e.data`, and sets the data to
/// filtered data before continuing the service event.
HookedServiceEventListener validateEvent(Validator validator,
    {String errorMessage: 'Invalid data.'}) {
  return (HookedServiceEvent e) async {
    var result = await asyncApplyValidator(
        validator, e.data as Map, (e.request?.app ?? e.service.app));

    if (result.errors.isNotEmpty) {
      throw new AngelHttpException.badRequest(
          message: errorMessage, errors: result.errors);
    }

    e.data
      ..clear()
      ..addAll(result.data);
  };
}

/// Asynchronously apply a [validator], running any [AngelMatcher]s.
Future<ValidationResult> asyncApplyValidator(
    Validator validator, Map data, Angel app) async {
  var result = validator.check(data);
  if (result.errors.isNotEmpty) return result;

  var errantKeys = <String>[], errors = <String>[];

  for (var key in result.data.keys) {
    var value = result.data[key];
    var description = new StringDescription("'$key': expected ");

    for (var rule in validator.rules[key]) {
      if (rule is AngelMatcher) {
        var r = await rule.matchesWithAngel(value, key, result.data, {}, app);

        if (!r) {
          errors.add(rule.describe(description).toString().trim());
          errantKeys.add(key);
          break;
        }
      }
    }
  }

  var m = new Map<String, dynamic>.from(result.data);
  for (var key in errantKeys) {
    m.remove(key);
  }

  return result.withData(m).withErrors(errors);
}
