library angel_auth;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:oauth2/oauth2.dart' as Oauth2;

part 'strategy.dart';

part 'middleware/require_auth.dart';

part 'middleware/serialization.dart';

part 'strategies/local.dart';

part 'strategies/oauth2.dart';

_validateString(String str) {
  return str != null && str.isNotEmpty;
}

const String FAILURE_REDIRECT = 'failureRedirect';
const String SUCCESS_REDIRECT = 'successRedirect';

class Auth {
  static List<AuthStrategy> strategies = [];
  static UserSerializer serializer;
  static UserDeserializer deserializer;

  call(Angel app) async {
    app.registerMiddleware('auth', requireAuth);
    app.before.add(_serializationMiddleware);
  }

  static authenticate(String type, [AngelAuthOptions options]) {
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

  static logout([AngelAuthOptions options]) {
    return (RequestContext req, ResponseContext res) async {
      for (AuthStrategy strategy in Auth.strategies) {
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

class AngelAuthOptions {
  String successRedirect;
  String failureRedirect;

  AngelAuthOptions({String this.successRedirect, String this.failureRedirect});
}

/// Configures an app to use angel_auth. :)
Future AngelAuth(Angel app) async {
  await app.configure(new Auth());
}
