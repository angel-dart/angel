import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';

/// Restricts access to a resource via authentication.
class RequireAuthorizationMiddleware extends AngelMiddleware {
  @override
  Future<bool> call(RequestContext req, ResponseContext res,
      {bool throwError: true}) async {
    bool _reject(ResponseContext res) {
      if (throwError) {
        res.statusCode = HttpStatus.FORBIDDEN;
        throw new AngelHttpException.Forbidden();
      } else
        return false;
    }

    if (req.properties.containsKey('user') || req.method == 'OPTIONS')
      return true;
    else
      return _reject(res);
  }
}
