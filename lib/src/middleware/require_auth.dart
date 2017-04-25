import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';

/// Restricts access to a resource via authentication. Constant instance.
const RequestMiddleware requireAuth = const RequireAuthorizationMiddleware();

/// Forces Basic authentication over the requested resource, with the given [realm] name, if no JWT is present.
///
/// [realm] defaults to `'angel_auth'`.
RequestHandler forceBasicAuth({String realm}) {
  return (RequestContext req, ResponseContext res) async {
    if (req.properties.containsKey('user')) return true;

    res
      ..statusCode = HttpStatus.UNAUTHORIZED
      ..headers[HttpHeaders.WWW_AUTHENTICATE] =
          'Basic realm="${realm ?? 'angel_auth'}"'
      ..end();
    return false;
  };
}

/// Restricts access to a resource via authentication.
class RequireAuthorizationMiddleware implements AngelMiddleware {
  const RequireAuthorizationMiddleware();

  @override
  Future<bool> call(RequestContext req, ResponseContext res,
      {bool throwError: true}) async {
    bool _reject(ResponseContext res) {
      if (throwError) {
        res.statusCode = HttpStatus.FORBIDDEN;
        throw new AngelHttpException.forbidden();
      } else
        return false;
    }

    if (req.properties.containsKey('user') || req.method == 'OPTIONS')
      return true;
    else
      return _reject(res);
  }
}
