import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';

/// Restricts access to a resource via authentication.
class RequireAuthorizationMiddleware extends BaseMiddleware {
  @override
  Future<bool> call(RequestContext req, ResponseContext res, {bool throwError: true}) async {
    bool _reject(ResponseContext res) {
      if (throwError) {
        res.status(HttpStatus.FORBIDDEN);
        throw new AngelHttpException.Forbidden();
      } else
        return false;
    }


    if (req.session.containsKey('userId'))
      return true;
    else if (req.headers.value("Authorization") != null) {
      var jwt = req.headers
          .value("Authorization")
          .replaceAll(new RegExp(r"^Bearer", caseSensitive: false), "")
          .trim();

      var split = jwt.split(".");
      if (split.length != 3) return _reject(res);

      Map header = JSON.decode(UTF8.decode(BASE64URL.decode(split[0])));

      if (header['typ'] != "JWT" || header['alg'] != "HS256")
        return _reject(res);

      Map payload = JSON.decode(UTF8.decode(BASE64URL.decode(split[1])));

      // Todo: JWT
      return false;
    } else
      return _reject(res);
  }
}