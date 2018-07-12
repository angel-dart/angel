import 'package:angel_framework/angel_framework.dart';

/// Forces Basic authentication over the requested resource, with the given [realm] name, if no JWT is present.
///
/// [realm] defaults to `'angel_auth'`.
RequestHandler forceBasicAuth({String realm, String userKey: 'user'}) {
  return (RequestContext req, ResponseContext res) async {
    if (req.properties.containsKey(userKey)) return true;

    res
      ..statusCode = 401
      ..headers['www-authenticate'] = 'Basic realm="${realm ?? 'angel_auth'}"'
      ..end();
    return false;
  };
}

/// Use [requireAuthentication] instead.
@deprecated
final RequestMiddleware requireAuth = requireAuthentication(userKey: 'user');

/// Restricts access to a resource via authentication.
RequestMiddleware requireAuthentication({String userKey: 'user'}) {
  return (RequestContext req, ResponseContext res,
      {bool throwError: true}) async {
    bool _reject(ResponseContext res) {
      if (throwError) {
        res.statusCode = 403;
        throw new AngelHttpException.forbidden();
      } else
        return false;
    }

    if (req.properties.containsKey(userKey) || req.method == 'OPTIONS')
      return true;
    else
      return _reject(res);
  };
}
