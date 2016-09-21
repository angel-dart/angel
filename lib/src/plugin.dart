import 'package:angel_framework/angel_framework.dart';
import 'middleware/require_auth.dart';
import 'defs.dart';
import 'options.dart';
import 'strategy.dart';

class AngelAuth extends AngelPlugin {
  RequireAuthorizationMiddleware _requireAuth = new RequireAuthorizationMiddleware();
  List<AuthStrategy> strategies = [];
  UserSerializer serializer;
  UserDeserializer deserializer;

  @override
  call(Angel app) async {
    app.container.singleton(this);

    if (runtimeType != AngelAuth)
      app.container.singleton(this, as: AngelAuth);

    app.registerMiddleware('auth', _requireAuth);
    app.before.add(_serializationMiddleware);
  }

  _serializationMiddleware(RequestContext req, ResponseContext res) async {
    if (await _requireAuth(req, res, throwError: false)) {
      req.properties['user'] = await deserializer(req.session['userId']);
    }

    return true;
  }

  authenticate(String type, [AngelAuthOptions options]) {
    return (RequestContext req, ResponseContext res) async {
      AuthStrategy strategy =
      strategies.firstWhere((AuthStrategy x) => x.name == type);
      var result = await strategy.authenticate(req, res, options);
      if (result == true)
        return result;
      else if (result != false) {
        req.session['userId'] = await serializer(result);
        return true;
      } else {
        throw new AngelHttpException.NotAuthenticated();
      }
    };
  }

  logout([AngelAuthOptions options]) {
    return (RequestContext req, ResponseContext res) async {
      for (AuthStrategy strategy in strategies) {
        if (!(await strategy.canLogout(req, res))) {
          if (options != null &&
              options.failureRedirect != null &&
              options.failureRedirect.isNotEmpty) {
            return res.redirect(options.failureRedirect);
          }

          return false;
        }
      }

      req.session.remove('userId');

      if (options != null &&
          options.successRedirect != null &&
          options.successRedirect.isNotEmpty) {
        return res.redirect(options.successRedirect);
      }

      return true;
    };
  }
}