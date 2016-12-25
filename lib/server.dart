/// Support for using `angel_validate` with the Angel Framework.
library angel_validate.server;

import 'package:angel_framework/angel_framework.dart';
import 'angel_validate.dart';
export 'angel_validate.dart';

/// Validates the data in `req.body`, and sets the body to
/// filtered data before continuing the response.
RequestMiddleware validate(Validator validator,
    {String errorMessage: 'Invalid data.'}) {
  return (RequestContext req, res) async {
    var result = validator.check(req.body);

    if (result.errors.isNotEmpty) {
      throw new AngelHttpException.BadRequest(
          message: errorMessage, errors: result.errors);
    }

    req.body
      ..clear()
      ..addAll(result.data);

    return true;
  };
}

/// Validates the data in `req.query`, and sets the query to
/// filtered data before continuing the response.
RequestMiddleware validateQuery(Validator validator,
    {String errorMessage: 'Invalid data.'}) {
  return (RequestContext req, res) async {
    var result = validator.check(req.query);

    if (result.errors.isNotEmpty) {
      throw new AngelHttpException.BadRequest(
          message: errorMessage, errors: result.errors);
    }

    req.query
      ..clear()
      ..addAll(result.data);

    return true;
  };
}

/// Validates the data in `e.data`, and sets the data to
/// filtered data before continuing the service event.
HookedServiceEventListener validateEvent(Validator validator,
    {String errorMessage: 'Invalid data.'}) {
  return (HookedServiceEvent e) {
    var result = validator.check(e.data);

    if (result.errors.isNotEmpty) {
      throw new AngelHttpException.BadRequest(
          message: errorMessage, errors: result.errors);
    }

    e.data
      ..clear()
      ..addAll(result.data);
  };
}
