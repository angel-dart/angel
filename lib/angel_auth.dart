library angel_auth;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';

part 'strategy.dart';

part 'middleware/require_auth.dart';

part 'middleware/serialization.dart';

part 'strategies/local.dart';

_validateString(String str) {
  return str != null && str.isNotEmpty;
}

class Auth {
  static List<AuthStrategy> strategies = [];
  static UserSerializer serializer;
  static UserDeserializer deserializer;

  call(Angel app) async {
    app.registerMiddleware('auth', requireAuth);
    app.before.add(_serializationMiddleware);
  }

  static authenticate(String type, [Map options]) {
    return (RequestContext req, ResponseContext res) async {
      AuthStrategy strategy =
      strategies.firstWhere((AuthStrategy x) => x.name == type);
      var result = await strategy.authenticate(
          req, res, options: options ?? {});
      if (result is bool)
        return result;
      else {
        req.session['userId'] = await serializer(result);
        return true;
      }
    };
  }
}

/// Configures an app to use angel_auth. :)
Future AngelAuth(Angel app) async {
  await app.configure(new Auth());
}
