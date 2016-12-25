/// Support for using `angel_validate` with the Angel Framework.
library angel_validate.server;

import 'package:angel_framework/angel_framework.dart';
import 'angel_validate.dart';
export 'angel_validate.dart';

/// Validates the data in `req.body`, and sets the body to
/// filtered data before continuing the response.
RequestMiddleware validate(Validator validator, {String errorMessage}) {

}

/// Validates the data in `req.body`, and sets the query to
/// filtered data before continuing the response.
RequestMiddleware validateQuery(Validator validator, {String errorMessage}) {

}

/// Validates the data in `e.data`, and sets the data to
/// filtered data before continuing the service event.
HookedServiceEventListener validateEvent(Validator validator) {

}

