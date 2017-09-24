import 'dart:async';
import 'dart:io';
import 'dart:math' as Math;
import 'package:angel_framework/angel_framework.dart';
import 'package:crypto/crypto.dart';
import 'middleware/require_auth.dart';
import 'auth_token.dart';
import 'defs.dart';
import 'options.dart';
import 'strategy.dart';

/// Handles authentication within an Angel application.
class AngelAuth<T> {
  Hmac _hs256;
  num _jwtLifeSpan;
  final StreamController<T> _onLogin = new StreamController<T>(),
      _onLogout = new StreamController<T>();
  Math.Random _random = new Math.Random.secure();
  final RegExp _rgxBearer = new RegExp(r"^Bearer");

  /// If `true` (default), then JWT's will be stored and retrieved from a `token` cookie.
  final bool allowCookie;

  /// If `true` (default), then users can include a JWT in the query string as `token`.
  final bool allowTokenInQuery;

  /// The name to register [requireAuth] as. Default: `auth`.
  String middlewareName;

  /// If `true` (default), then JWT's will be considered invalid if used from a different IP than the first user's it was issued to.
  ///
  /// This is a security provision. Even if a user's JWT is stolen, a remote attacker will not be able to impersonate anyone.
  bool enforceIp;

  /// The endpoint to mount [reviveJwt] at. If `null`, then no revival route is mounted. Default: `/auth/token`.
  String reviveTokenEndpoint;

  /// A set of [AuthStrategy] instances used to authenticate users.
  List<AuthStrategy> strategies = [];

  /// Serializes a user into a unique identifier associated only with one identity.
  UserSerializer<T> serializer;

  /// Deserializes a unique identifier into its associated identity. In most cases, this is a user object or model instance.
  UserDeserializer<T> deserializer;

  /// Fires the result of [deserializer] whenever a user signs in to the application.
  Stream<T> get onLogin => _onLogin.stream;

  /// Fires `req.user`, which is usually the result of [deserializer], whenever a user signs out of the application.
  Stream<T> get onLogout => _onLogout.stream;

  /// The [Hmac] being used to encode JWT's.
  Hmac get hmac => _hs256;

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
      this.enforceIp: true,
      this.middlewareName: 'auth',
      this.reviveTokenEndpoint: "/auth/token"})
      : super() {
    _hs256 = new Hmac(sha256, (jwtKey ?? _randomString()).codeUnits);
    _jwtLifeSpan = jwtLifeSpan ?? -1;
  }

  Future configureServer(Angel app) async {
    if (serializer == null)
      throw new StateError(
          'An `AngelAuth` plug-in was called without its `serializer` being set. All authentication will fail.');
    if (deserializer == null)
      throw new StateError(
          'An `AngelAuth` plug-in was called without its `deserializer` being set. All authentication will fail.');

    app.container.singleton(this);
    if (runtimeType != AngelAuth) app.container.singleton(this, as: AngelAuth);

    app.registerMiddleware(middlewareName, requireAuth);

    if (reviveTokenEndpoint != null) {
      app.post(reviveTokenEndpoint, reviveJwt);
    }

    app.shutdownHooks.add((_) {
      _onLogin.close();
    });
  }

  void _apply(RequestContext req, AuthToken token, user) {
    req
      ..inject(AuthToken, req.properties['token'] = token)
      ..inject(user.runtimeType, req.properties["user"] = user);
  }

  /// A middleware that decodes a JWT from a request, and injects a corresponding user.
  Future decodeJwt(RequestContext req, ResponseContext res) async {
    if (req.method == "POST" && req.path == reviveTokenEndpoint) {
      return await reviveJwt(req, res);
    }

    String jwt = getJwt(req);

    if (jwt != null) {
      var token = new AuthToken.validate(jwt, _hs256);

      if (enforceIp) {
        if (req.ip != null && req.ip != token.ipAddress)
          throw new AngelHttpException.forbidden(
              message: "JWT cannot be accessed from this IP address.");
      }

      if (token.lifeSpan > -1) {
        token.issuedAt.add(new Duration(milliseconds: token.lifeSpan));

        if (!token.issuedAt.isAfter(new DateTime.now()))
          throw new AngelHttpException.forbidden(message: "Expired JWT.");
      }

      final user = await deserializer(token.userId);
      _apply(req, token, user);
    }

    return true;
  }

  /// Retrieves a JWT from a request, if any was sent at all.
  String getJwt(RequestContext req) {
    if (req.headers.value("Authorization") != null) {
      final authHeader = req.headers.value("Authorization");

      // Allow Basic auth to fall through
      if (_rgxBearer.hasMatch(authHeader))
        return authHeader.replaceAll(_rgxBearer, "").trim();
    } else if (allowCookie &&
        req.cookies.any((cookie) => cookie.name == "token")) {
      return req.cookies.firstWhere((cookie) => cookie.name == "token").value;
    } else if (allowTokenInQuery && req.query['token'] is String) {
      return req.query['token'];
    }

    return null;
  }

  /// Attempts to revive an expired (or still alive) JWT.
  Future<Map<String, dynamic>> reviveJwt(RequestContext req, ResponseContext res) async {
    try {
      var jwt = getJwt(req);

      if (jwt == null) {
        var body = await req.lazyBody();
        jwt = body['token'];
      }
      if (jwt == null) {
        throw new AngelHttpException.forbidden(message: "No JWT provided");
      } else {
        var token = new AuthToken.validate(jwt, _hs256);
        if (enforceIp) {
          if (req.ip != token.ipAddress)
            throw new AngelHttpException.forbidden(
                message: "JWT cannot be accessed from this IP address.");
        }

        if (token.lifeSpan > -1) {
          token.issuedAt.add(new Duration(milliseconds: token.lifeSpan));

          if (!token.issuedAt.isAfter(new DateTime.now())) {
            print(
                'Token has indeed expired! Resetting assignment date to current timestamp...');
            // Extend its lifespan by changing iat
            token.issuedAt = new DateTime.now();
          }
        }

        if (allowCookie)
          res.cookies.add(new Cookie('token', token.serialize(_hs256)));

        final data = await deserializer(token.userId);
        return {'data': data, 'token': token.serialize(_hs256)};
      }
    } catch (e) {
      if (e is AngelHttpException) rethrow;
      throw new AngelHttpException.badRequest(message: "Malformed JWT");
    }
  }

  /// Attempts to authenticate a user using one or more strategies.
  ///
  /// [type] is a strategy name to try, or a `List` of such.
  ///
  /// If a strategy returns `null` or `false`, either the next one is tried,
  /// or a `401 Not Authenticated` is thrown, if it is the last one.
  ///
  /// Any other result is considered an authenticated user, and terminates the loop.
  RequestHandler authenticate(type, [AngelAuthOptions options]) {
    return (RequestContext req, ResponseContext res) async {
      List<String> names = [];
      var arr = type is Iterable ? type.toList() : [type];

      for (var t in arr) {
        var n = t
            .split(',')
            .map((s) => s.trim())
            .where((String s) => s.isNotEmpty)
            .toList();
        names.addAll(n);
      }

      for (int i = 0; i < names.length; i++) {
        var name = names[i];

        AuthStrategy strategy = strategies.firstWhere(
            (AuthStrategy x) => x.name == name,
            orElse: () =>
                throw new ArgumentError('No strategy "$name" found.'));
        var result = await strategy.authenticate(req, res, options);
        if (result == true)
          return result;
        else if (result != false) {
          var userId = await serializer(result);

          // Create JWT
          var token = new AuthToken(
              userId: userId, lifeSpan: _jwtLifeSpan, ipAddress: req.ip);
          var jwt = token.serialize(_hs256);

          if (options?.tokenCallback != null) {
            var r = await options.tokenCallback(
                req, res, token, req.properties["user"] = result);
            if (r != null) return r;
          }

          _apply(req, token, result);

          if (allowCookie) res.cookies.add(new Cookie("token", jwt));

          if (options?.callback != null) {
            return await options.callback(req, res, jwt);
          }

          if (options?.successRedirect?.isNotEmpty == true) {
            res.redirect(options.successRedirect, code: HttpStatus.OK);
            return false;
          } else if (options?.canRespondWithJson != false &&
              req.headers.value("accept") != null &&
              (req.headers.value("accept").contains("application/json") ||
                  req.headers.value("accept").contains("*/*") ||
                  req.headers.value("accept").contains("application/*"))) {
            var user = await deserializer(await serializer(result));
            _onLogin.add(user);
            return {"data": user, "token": jwt};
          }

          return true;
        } else {
          if (i < names.length - 1) continue;
          // Check if not redirect
          if (res.statusCode == 301 ||
              res.statusCode == 302 ||
              res.headers.containsKey(HttpHeaders.LOCATION))
            return false;
          else
            throw new AngelHttpException.notAuthenticated();
        }
      }
    };
  }

  /// Log a user in on-demand.
  Future login(AuthToken token, RequestContext req, ResponseContext res) async {
    var user = await deserializer(token.userId);
    _apply(req, token, user);
    _onLogin.add(user);

    if (allowCookie)
      res.cookies.add(new Cookie('token', token.serialize(_hs256)));
  }

  /// Log a user in on-demand.
  Future loginById(userId, RequestContext req, ResponseContext res) async {
    var user = await deserializer(userId);
    var token = new AuthToken(
        userId: userId, lifeSpan: _jwtLifeSpan, ipAddress: req.ip);
    _apply(req, token, user);
    _onLogin.add(user);

    if (allowCookie)
      res.cookies.add(new Cookie('token', token.serialize(_hs256)));
  }

  /// Log an authenticated user out.
  RequestMiddleware logout([AngelAuthOptions options]) {
    return (RequestContext req, ResponseContext res) async {
      for (AuthStrategy strategy in strategies) {
        if (!(await strategy.canLogout(req, res))) {
          if (options != null &&
              options.failureRedirect != null &&
              options.failureRedirect.isNotEmpty) {
            res.redirect(options.failureRedirect);
          }

          return false;
        }
      }

      var user = req.grab('user');
      if (user != null) _onLogout.add(user);

      req.injections..remove(AuthToken)..remove('user');
      req.properties.remove('user');

      if (allowCookie == true)
        res.cookies.removeWhere((cookie) => cookie.name == "token");

      if (options != null &&
          options.successRedirect != null &&
          options.successRedirect.isNotEmpty) {
        res.redirect(options.successRedirect);
      }

      return true;
    };
  }
}
