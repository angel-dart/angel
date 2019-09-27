/// Support for using `angel_validate` with the Angel Framework.
library angel_validate.server;

import 'dart:async';

import 'package:angel_framework/angel_framework.dart';
import 'src/async.dart';
import 'angel_validate.dart';
export 'src/async.dart';
export 'angel_validate.dart';

/// Auto-parses numbers in `req.bodyAsMap`.
RequestHandler autoParseBody(List<String> fields) {
  return (RequestContext req, res) async {
    await req.parseBody();
    req.bodyAsMap.addAll(autoParse(req.bodyAsMap, fields));
    return true;
  };
}

/// Auto-parses numbers in `req.queryParameters`.
RequestHandler autoParseQuery(List<String> fields) {
  return (RequestContext req, res) async {
    req.queryParameters.addAll(autoParse(req.queryParameters, fields));
    return true;
  };
}

/// Filters unwanted data out of `req.bodyAsMap`.
RequestHandler filterBody(Iterable<String> only) {
  return (RequestContext req, res) async {
    await req.parseBody();
    var filtered = filter(req.bodyAsMap, only);
    req.bodyAsMap
      ..clear()
      ..addAll(filtered);
    return true;
  };
}

/// Filters unwanted data out of `req.queryParameters`.
RequestHandler filterQuery(Iterable<String> only) {
  return (RequestContext req, res) async {
    var filtered = filter(req.queryParameters, only);
    req.queryParameters
      ..clear()
      ..addAll(filtered);
    return true;
  };
}

/// Validates the data in `req.bodyAsMap`, and sets the body to
/// filtered data before continuing the response.
RequestHandler validate(Validator validator,
    {String errorMessage = 'Invalid data.'}) {
  return (RequestContext req, res) async {
    await req.parseBody();
    var result = await asyncApplyValidator(validator, req.bodyAsMap, req.app);

    if (result.errors.isNotEmpty) {
      throw AngelHttpException.badRequest(
          message: errorMessage, errors: result.errors);
    }

    req.bodyAsMap
      ..clear()
      ..addAll(result.data);

    return true;
  };
}

/// Validates the data in `req.queryParameters`, and sets the query to
/// filtered data before continuing the response.
RequestHandler validateQuery(Validator validator,
    {String errorMessage = 'Invalid data.'}) {
  return (RequestContext req, res) async {
    var result =
        await asyncApplyValidator(validator, req.queryParameters, req.app);

    if (result.errors.isNotEmpty) {
      throw AngelHttpException.badRequest(
          message: errorMessage, errors: result.errors);
    }

    req.queryParameters
      ..clear()
      ..addAll(result.data);

    return true;
  };
}

/// Validates the data in `e.data`, and sets the data to
/// filtered data before continuing the service event.
HookedServiceEventListener validateEvent(Validator validator,
    {String errorMessage = 'Invalid data.'}) {
  return (HookedServiceEvent e) async {
    var result = await asyncApplyValidator(
        validator, e.data as Map, (e.request?.app ?? e.service.app));

    if (result.errors.isNotEmpty) {
      throw AngelHttpException.badRequest(
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
    var description = StringDescription("'$key': expected ");

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

  var m = Map<String, dynamic>.from(result.data);
  for (var key in errantKeys) {
    m.remove(key);
  }

  return result.withData(m).withErrors(errors);
}
