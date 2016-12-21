library angel_framework.http.base_middleware;

import 'dart:async';
import 'request_context.dart';
import 'response_context.dart';

abstract class AngelMiddleware {
  Future<bool> call(RequestContext req, ResponseContext res);
}

@Deprecated('Use AngelMiddleware instead')
abstract class BaseMiddleware {
  Future<bool> call(RequestContext req, ResponseContext res);
}