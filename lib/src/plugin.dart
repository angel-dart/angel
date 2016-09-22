import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as Math;
import 'package:angel_framework/angel_framework.dart';
import 'package:crypto/crypto.dart';
import 'middleware/require_auth.dart';
import 'auth_token.dart';
import 'defs.dart';
import 'options.dart';
import 'strategy.dart';

class AngelAuth extends AngelPlugin {
  Hmac _hs256;
  num _jwtLifeSpan;
  Math.Random _random = new Math.Random.secure();
  final RegExp _rgxBearer = new RegExp(r"^Bearer");
  RequireAuthorizationMiddleware _requireAuth =
      new RequireAuthorizationMiddleware();
  bool enforceIp;
  String reviveTokenEndpoint;
  List<AuthStrategy> strategies = [];
  UserSerializer serializer;
  UserDeserializer deserializer;

  String _randomString({int length: 32, String validChars: "ABCDEFHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"}) {
    var chars = <int>[];

    while (chars.length < length) chars.add(_random.nextInt(validChars.length));

    return new String.fromCharCodes(chars);
  }

  AngelAuth({String jwtKey, num jwtLifeSpan, this.enforceIp, this.reviveTokenEndpoint: "/auth/token"}) : super() {
    _hs256 = new Hmac(sha256, (jwtKey ?? _randomString()).codeUnits);
    _jwtLifeSpan = jwtLifeSpan ?? -1;
  }

  @override
  call(Angel app) async {
    app.container.singleton(this);
    if (runtimeType != AngelAuth) app.container.singleton(this, as: AngelAuth);

    app.before.add(_decodeJwt);
    app.registerMiddleware('auth', _requireAuth);

    if (reviveTokenEndpoint != null) {
      app.post(reviveTokenEndpoint, _reviveJwt);
    }
  }

  _decodeJwt(RequestContext req, ResponseContext res) async {
    if (req.path == reviveTokenEndpoint) {
      // Shouldn't block invalid JWT if we are reviving it
      return true;
    }

    String jwt = _getJwt(req);

    if (jwt != null) {
      var token = new AuthToken.validate(jwt, _hs256);

      if (enforceIp) {
        if (req.ip != token.ipAddress)
          throw new AngelHttpException.Forbidden(
              message: "JWT cannot be accessed from this IP address.");
      }

      if (token.lifeSpan > -1) {
        token.issuedAt.add(new Duration(milliseconds: token.lifeSpan));

        if (!token.issuedAt.isAfter(new DateTime.now()))
          throw new AngelHttpException.Forbidden(message: "Expired JWT.");
      }

      req.properties["user"] = await deserializer(token.userId);
    }

    return true;
  }


  _getJwt(RequestContext req) {
    if (req.headers.value("Authorization") != null) {
      return req.headers.value("Authorization").replaceAll(_rgxBearer, "").trim();
    } else if (req.cookies.any((cookie) => cookie.name == "token")) {
      return req.cookies.firstWhere((cookie) => cookie.name == "token").value;
    }

    return null;
  }

  _reviveJwt(RequestContext req, ResponseContext res) async {
    try {
      var jwt = _getJwt(req);

      if (jwt == null) {
        throw new AngelHttpException.Forbidden(message: "No JWT provided");
      } else {
        var token = new AuthToken.validate(jwt, _hs256);

        if (enforceIp) {
          if (req.ip != token.ipAddress)
            throw new AngelHttpException.Forbidden(
                message: "JWT cannot be accessed from this IP address.");
        }

        if (token.lifeSpan > -1) {
          token.issuedAt.add(new Duration(milliseconds: token.lifeSpan));

          if (!token.issuedAt.isAfter(new DateTime.now())) {
            // Extend its lifespan by changing iat
            token.issuedAt = new DateTime.now();
          }
        }

        return token.toJson();
      }
    } catch(e) {
      if (e is AngelHttpException)
        rethrow;
      throw new AngelHttpException.BadRequest(message: "Malformed JWT");
    }
  }

  authenticate(String type, [AngelAuthOptions options]) {
    return (RequestContext req, ResponseContext res) async {
      AuthStrategy strategy =
          strategies.firstWhere((AuthStrategy x) => x.name == type);
      var result = await strategy.authenticate(req, res, options);
      if (result == true)
        return result;
      else if (result != false) {
        var userId = await serializer(result);

        // Create JWT
        var jwt = new AuthToken(userId: userId, lifeSpan: _jwtLifeSpan)
            .serialize(_hs256);
        req.cookies.add(new Cookie("token", jwt));

        if (req.headers.value("accept") != null &&
            (req.headers.value("accept").contains("application/json") ||
                req.headers.value("accept").contains("*/*") ||
                req.headers.value("accept").contains("application/*"))) {
          return {"data": result, "token": jwt};
        } else if (options != null && options.successRedirect != null &&
            options.successRedirect.isNotEmpty) {
          return res.redirect(options.successRedirect, code: HttpStatus.OK);
        }

        return true;
      } else {
        await authenticationFailure(req, res);
      }
    };
  }

  Future authenticationFailure(RequestContext req, ResponseContext res) async {
    throw new AngelHttpException.NotAuthenticated();
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

      req.cookies.removeWhere((cookie) => cookie.name == "token");

      if (options != null &&
          options.successRedirect != null &&
          options.successRedirect.isNotEmpty) {
        return res.redirect(options.successRedirect);
      }

      return true;
    };
  }
}
