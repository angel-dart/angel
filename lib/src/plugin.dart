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
  final bool allowCookie;
  final bool allowTokenInQuery;
  String middlewareName;
  bool debug;
  bool enforceIp;
  String reviveTokenEndpoint;
  List<AuthStrategy> strategies = [];
  UserSerializer serializer;
  UserDeserializer deserializer;

  String _randomString(
      {int length: 32,
      String validChars:
          "ABCDEFHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"}) {
    var chars = <int>[];

    while (chars.length < length) chars.add(_random.nextInt(validChars.length));

    return new String.fromCharCodes(chars);
  }

  AngelAuth(
      {String jwtKey,
      num jwtLifeSpan,
      this.allowCookie: true,
      this.allowTokenInQuery: true,
      this.debug: false,
      this.enforceIp: true,
      this.middlewareName: 'auth',
      this.reviveTokenEndpoint: "/auth/token"})
      : super() {
    _hs256 = new Hmac(sha256, (jwtKey ?? _randomString()).codeUnits);
    _jwtLifeSpan = jwtLifeSpan ?? -1;
  }

  @override
  call(Angel app) async {
    app.container.singleton(this);
    if (runtimeType != AngelAuth) app.container.singleton(this, as: AngelAuth);

    app.before.add(decodeJwt);
    app.registerMiddleware(middlewareName, _requireAuth);

    if (reviveTokenEndpoint != null) {
      app.post(reviveTokenEndpoint, reviveJwt);
    }
  }

  decodeJwt(RequestContext req, ResponseContext res) async {
    if (req.method == "POST" && req.path == reviveTokenEndpoint) {
      // Shouldn't block invalid JWT if we are reviving it
      if (debug) print('Token revival endpoint accessed.');
      return await reviveJwt(req, res);
    }

    if (debug) {
      print('Enforcing JWT authentication...');
    }

    String jwt = getJwt(req);

    if (debug) {
      print('Found JWT: $jwt');
    }

    if (jwt != null) {
      var token = new AuthToken.validate(jwt, _hs256);

      if (debug) {
        print('Decoded auth token: ${token.toJson()}');
      }

      if (enforceIp) {
        if (debug) {
          print(
              'Token IP: ${token.ipAddress}. Current request sent from: ${req.ip}');
        }

        if (req.ip != null && req.ip != token.ipAddress)
          throw new AngelHttpException.Forbidden(
              message: "JWT cannot be accessed from this IP address.");
      }

      if (token.lifeSpan > -1) {
        if (debug) {
          print("Making sure this token hasn't already expired...");
        }

        token.issuedAt.add(new Duration(milliseconds: token.lifeSpan));

        if (!token.issuedAt.isAfter(new DateTime.now()))
          throw new AngelHttpException.Forbidden(message: "Expired JWT.");
      } else if (debug) {
        print('This token has an infinite life span.');
      }

      if (debug) {
        print('Now deserializing from this userId: ${token.userId}');
      }

      req.inject(AuthToken, req.properties['token'] = token);
      req.properties["user"] = await deserializer(token.userId);
    }

    return true;
  }

  getJwt(RequestContext req) {
    if (debug) {
      print('Attempting to parse JWT');
    }

    if (req.headers.value("Authorization") != null) {
      if (debug) {
        print('Found Auth header');
      }

      final authHeader = req.headers.value("Authorization");

      // Allow Basic auth to fall through
      if (_rgxBearer.hasMatch(authHeader))
        return authHeader.replaceAll(_rgxBearer, "").trim();
    } else if (req.cookies.any((cookie) => cookie.name == "token")) {
      print('Request has "token" cookie...');
      return req.cookies.firstWhere((cookie) => cookie.name == "token").value;
    } else if (allowTokenInQuery && req.query['token'] is String) {
      return req.query['token'];
    }

    return null;
  }

  reviveJwt(RequestContext req, ResponseContext res) async {
    try {
      if (debug) print('Attempting to revive JWT...');

      var jwt = getJwt(req);

      if (debug) print('Found JWT: $jwt');

      if (jwt == null) {
        throw new AngelHttpException.Forbidden(message: "No JWT provided");
      } else {
        var token = new AuthToken.validate(jwt, _hs256);

        if (debug) print('Validated and deserialized: $token');

        if (enforceIp) {
          if (debug)
            print(
                'Token IP: ${token.ipAddress}. Current request sent from: ${req.ip}');

          if (req.ip != token.ipAddress)
            throw new AngelHttpException.Forbidden(
                message: "JWT cannot be accessed from this IP address.");
        }

        if (token.lifeSpan > -1) {
          if (debug) {
            print(
                'Checking if token has expired... Life span is ${token.lifeSpan}');
          }

          token.issuedAt.add(new Duration(milliseconds: token.lifeSpan));

          if (!token.issuedAt.isAfter(new DateTime.now())) {
            print(
                'Token has indeed expired! Resetting assignment date to current timestamp...');
            // Extend its lifespan by changing iat
            token.issuedAt = new DateTime.now();
          } else if (debug) {
            print('Token has not expired yet.');
          }
        } else if (debug) {
          print('This token never expires, so it is still valid.');
        }

        if (debug) {
          print('Final, valid token: ${token.toJson()}');
        }

        res.cookies.add(new Cookie('token', token.serialize(_hs256)));
        return token.toJson();
      }
    } catch (e, st) {
      if (debug) {
        print('An error occurred while reviving this token.');
        print(e);
        print(st);
      }

      if (e is AngelHttpException) rethrow;
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
        var jwt = new AuthToken(
                userId: userId, lifeSpan: _jwtLifeSpan, ipAddress: req.ip)
            .serialize(_hs256);
        req.inject(AuthToken, jwt);

        if (allowCookie) req.cookies.add(new Cookie("token", jwt));

        if (options?.canRespondWithJson != false &&
            req.headers.value("accept") != null &&
            (req.headers.value("accept").contains("application/json") ||
                req.headers.value("accept").contains("*/*") ||
                req.headers.value("accept").contains("application/*"))) {
          return {"data": result, "token": jwt};
        } else if (options != null &&
            options.successRedirect != null &&
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
