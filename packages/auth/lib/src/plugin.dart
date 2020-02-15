import 'dart:async';
import 'dart:io';
import 'dart:math' as Math;
import 'package:angel_framework/angel_framework.dart';
import 'package:crypto/crypto.dart';
import 'auth_token.dart';
import 'options.dart';
import 'strategy.dart';

/// Handles authentication within an Angel application.
class AngelAuth<User> {
  Hmac _hs256;
  int _jwtLifeSpan;
  final StreamController<User> _onLogin = StreamController<User>(),
      _onLogout = StreamController<User>();
  Math.Random _random = Math.Random.secure();
  final RegExp _rgxBearer = RegExp(r"^Bearer");

  /// If `true` (default), then JWT's will be stored and retrieved from a `token` cookie.
  final bool allowCookie;

  /// If `true` (default), then users can include a JWT in the query string as `token`.
  final bool allowTokenInQuery;

  /// Whether emitted cookies should have the `secure` and `HttpOnly` flags,
  /// as well as being restricted to a specific domain.
  final bool secureCookies;

  /// A domain to restrict emitted cookies to.
  ///
  /// Only applies if [allowCookie] is `true`.
  final String cookieDomain;

  /// A path to restrict emitted cookies to.
  ///
  /// Only applies if [allowCookie] is `true`.
  final String cookiePath;

  /// If `true` (default), then JWT's will be considered invalid if used from a different IP than the first user's it was issued to.
  ///
  /// This is a security provision. Even if a user's JWT is stolen, a remote attacker will not be able to impersonate anyone.
  final bool enforceIp;

  /// The endpoint to mount [reviveJwt] at. If `null`, then no revival route is mounted. Default: `/auth/token`.
  String reviveTokenEndpoint;

  /// A set of [AuthStrategy] instances used to authenticate users.
  Map<String, AuthStrategy<User>> strategies = {};

  /// Serializes a user into a unique identifier associated only with one identity.
  FutureOr Function(User) serializer;

  /// Deserializes a unique identifier into its associated identity. In most cases, this is a user object or model instance.
  FutureOr<User> Function(Object) deserializer;

  /// Fires the result of [deserializer] whenever a user signs in to the application.
  Stream<User> get onLogin => _onLogin.stream;

  /// Fires `req.user`, which is usually the result of [deserializer], whenever a user signs out of the application.
  Stream<User> get onLogout => _onLogout.stream;

  /// The [Hmac] being used to encode JWT's.
  Hmac get hmac => _hs256;

  String _randomString(
      {int length = 32,
      String validChars =
          "ABCDEFHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"}) {
    var chars = <int>[];
    while (chars.length < length) chars.add(_random.nextInt(validChars.length));
    return String.fromCharCodes(chars);
  }

  /// `jwtLifeSpan` - should be in *milliseconds*.
  AngelAuth(
      {String jwtKey,
      this.serializer,
      this.deserializer,
      num jwtLifeSpan,
      this.allowCookie = true,
      this.allowTokenInQuery = true,
      this.enforceIp = true,
      this.cookieDomain,
      this.cookiePath = '/',
      this.secureCookies = true,
      this.reviveTokenEndpoint = "/auth/token"})
      : super() {
    _hs256 = Hmac(sha256, (jwtKey ?? _randomString()).codeUnits);
    _jwtLifeSpan = jwtLifeSpan?.toInt() ?? -1;
  }

  /// Configures an Angel server to decode and validate JSON Web tokens on demand,
  /// whenever an instance of [User] is injected.
  Future<void> configureServer(Angel app) async {
    if (serializer == null)
      throw StateError(
          'An `AngelAuth` plug-in was called without its `serializer` being set. All authentication will fail.');
    if (deserializer == null)
      throw StateError(
          'An `AngelAuth` plug-in was called without its `deserializer` being set. All authentication will fail.');

    app.container.registerSingleton(this);
    if (runtimeType != AngelAuth)
      app.container.registerSingleton(this, as: AngelAuth);

    if (!app.container.has<_AuthResult<User>>()) {
      app.container
          .registerLazySingleton<Future<_AuthResult<User>>>((container) async {
        var req = container.make<RequestContext>();
        var res = container.make<ResponseContext>();
        var result = await _decodeJwt(req, res);
        if (result != null) {
          return result;
        } else {
          throw AngelHttpException.forbidden();
        }
      });

      app.container.registerLazySingleton<Future<User>>((container) async {
        var result = await container.makeAsync<_AuthResult<User>>();
        return result.user;
      });

      app.container.registerLazySingleton<Future<AuthToken>>((container) async {
        var result = await container.makeAsync<_AuthResult<User>>();
        return result.token;
      });
    }

    if (reviveTokenEndpoint != null) {
      app.post(reviveTokenEndpoint, reviveJwt);
    }

    app.shutdownHooks.add((_) {
      _onLogin.close();
    });
  }

  void _apply(
      RequestContext req, ResponseContext res, AuthToken token, User user) {
    if (!req.container.has<User>()) {
      req.container.registerSingleton<User>(user);
    }

    if (!req.container.has<AuthToken>()) {
      req.container.registerSingleton<AuthToken>(token);
    }

    if (allowCookie == true) {
      _addProtectedCookie(res, 'token', token.serialize(_hs256));
    }
  }

  /// DEPRECATED: A middleware that decodes a JWT from a request, and injects a corresponding user.
  ///
  /// Now that `package:angel_framework` supports asynchronous injections, this middleware
  /// is no longer directly necessary. Instead, call [configureServer]. You can then use
  /// `makeAsync<User>`, or Angel's injections directly:
  ///
  /// ```dart
  /// var auth = AngelAuth<User>(...);
  /// await app.configure(auth.configureServer);
  ///
  /// app.get('/hmm', (User user) async {
  ///   // `package:angel_auth` decodes the JWT on demand.
  ///   print(user.name);
  /// });
  ///
  /// @Expose('/my')
  /// class MyController extends Controller {
  ///   @Expose('/hmm')
  ///   String getUsername(User user) => user.name
  /// }
  /// ```
  @deprecated
  Future decodeJwt(RequestContext req, ResponseContext res) async {
    if (req.method == "POST" && req.path == reviveTokenEndpoint) {
      return await reviveJwt(req, res);
    } else {
      await _decodeJwt(req, res);
      return true;
    }
  }

  Future<_AuthResult<User>> _decodeJwt(
      RequestContext req, ResponseContext res) async {
    String jwt = getJwt(req);

    if (jwt != null) {
      var token = AuthToken.validate(jwt, _hs256);

      if (enforceIp) {
        if (req.ip != null && req.ip != token.ipAddress)
          throw AngelHttpException.forbidden(
              message: "JWT cannot be accessed from this IP address.");
      }

      if (token.lifeSpan > -1) {
        var expiry =
            token.issuedAt.add(Duration(milliseconds: token.lifeSpan.toInt()));

        if (!expiry.isAfter(DateTime.now()))
          throw AngelHttpException.forbidden(message: "Expired JWT.");
      }

      var user = await deserializer(token.userId);
      _apply(req, res, token, user);
      return _AuthResult(user, token);
    }

    return null;
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
    } else if (allowTokenInQuery &&
        req.uri.queryParameters['token'] is String) {
      return req.uri.queryParameters['token']?.toString();
    }

    return null;
  }

  void _addProtectedCookie(ResponseContext res, String name, String value) {
    if (!res.cookies.any((c) => c.name == name)) {
      res.cookies.add(protectCookie(Cookie(name, value)));
    }
  }

  /// Applies security protections to a [cookie].
  Cookie protectCookie(Cookie cookie) {
    if (secureCookies != false) {
      cookie.httpOnly = true;
      cookie.secure = true;
    }

    if (_jwtLifeSpan > 0) {
      cookie.maxAge ??= _jwtLifeSpan < 0 ? -1 : _jwtLifeSpan ~/ 1000;
      cookie.expires ??=
          DateTime.now().add(Duration(milliseconds: _jwtLifeSpan));
    }

    cookie.domain ??= cookieDomain;
    cookie.path ??= cookiePath;
    return cookie;
  }

  /// Attempts to revive an expired (or still alive) JWT.
  Future<Map<String, dynamic>> reviveJwt(
      RequestContext req, ResponseContext res) async {
    try {
      var jwt = getJwt(req);

      if (jwt == null) {
        var body = await req.parseBody().then((_) => req.bodyAsMap);
        jwt = body['token']?.toString();
      }
      if (jwt == null) {
        throw AngelHttpException.forbidden(message: "No JWT provided");
      } else {
        var token = AuthToken.validate(jwt, _hs256);
        if (enforceIp) {
          if (req.ip != token.ipAddress)
            throw AngelHttpException.forbidden(
                message: "JWT cannot be accessed from this IP address.");
        }

        if (token.lifeSpan > -1) {
          var expiry = token.issuedAt
              .add(Duration(milliseconds: token.lifeSpan.toInt()));

          if (!expiry.isAfter(DateTime.now())) {
            //print(
            //    'Token has indeed expired! Resetting assignment date to current timestamp...');
            // Extend its lifespan by changing iat
            token.issuedAt = DateTime.now();
          }
        }

        if (allowCookie) {
          _addProtectedCookie(res, 'token', token.serialize(_hs256));
        }

        final data = await deserializer(token.userId);
        return {'data': data, 'token': token.serialize(_hs256)};
      }
    } catch (e) {
      if (e is AngelHttpException) rethrow;
      throw AngelHttpException.badRequest(message: "Malformed JWT");
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
  RequestHandler authenticate(type, [AngelAuthOptions<User> options]) {
    return (RequestContext req, ResponseContext res) async {
      List<String> names = [];
      var arr = type is Iterable
          ? type.map((x) => x.toString()).toList()
          : [type.toString()];

      for (String t in arr) {
        var n = t
            .split(',')
            .map((s) => s.trim())
            .where((String s) => s.isNotEmpty)
            .toList();
        names.addAll(n);
      }

      for (int i = 0; i < names.length; i++) {
        var name = names[i];

        var strategy = strategies[name] ??=
            throw ArgumentError('No strategy "$name" found.');

        var hasExisting = req.container.has<User>();
        var result = hasExisting
            ? req.container.make<User>()
            : await strategy.authenticate(req, res, options);
        if (result == true)
          return result;
        else if (result != false && result != null) {
          var userId = await serializer(result);

          // Create JWT
          var token = AuthToken(
              userId: userId, lifeSpan: _jwtLifeSpan, ipAddress: req.ip);
          var jwt = token.serialize(_hs256);

          if (options?.tokenCallback != null) {
            if (!req.container.has<User>()) {
              req.container.registerSingleton<User>(result);
            }

            var r = await options.tokenCallback(req, res, token, result);
            if (r != null) return r;
            jwt = token.serialize(_hs256);
          }

          _apply(req, res, token, result);

          if (allowCookie) {
            _addProtectedCookie(res, 'token', jwt);
          }

          if (options?.callback != null) {
            return await options.callback(req, res, jwt);
          }

          if (options?.successRedirect?.isNotEmpty == true) {
            await res.redirect(options.successRedirect);
            return false;
          } else if (options?.canRespondWithJson != false &&
              req.accepts('application/json')) {
            var user = hasExisting
                ? result
                : await deserializer(await serializer(result));
            _onLogin.add(user);
            return {"data": user, "token": jwt};
          }

          return true;
        } else {
          if (i < names.length - 1) continue;
          // Check if not redirect
          if (res.statusCode == 301 ||
              res.statusCode == 302 ||
              res.headers.containsKey('location'))
            return false;
          else if (options?.failureRedirect != null) {
            await res.redirect(options.failureRedirect);
            return false;
          } else
            throw AngelHttpException.notAuthenticated();
        }
      }
    };
  }

  /// Log a user in on-demand.
  Future login(AuthToken token, RequestContext req, ResponseContext res) async {
    var user = await deserializer(token.userId);
    _apply(req, res, token, user);
    _onLogin.add(user);

    if (allowCookie) {
      _addProtectedCookie(res, 'token', token.serialize(_hs256));
    }
  }

  /// Log a user in on-demand.
  Future loginById(userId, RequestContext req, ResponseContext res) async {
    var user = await deserializer(userId);
    var token =
        AuthToken(userId: userId, lifeSpan: _jwtLifeSpan, ipAddress: req.ip);
    _apply(req, res, token, user);
    _onLogin.add(user);

    if (allowCookie) {
      _addProtectedCookie(res, 'token', token.serialize(_hs256));
    }
  }

  /// Log an authenticated user out.
  RequestHandler logout([AngelAuthOptions<User> options]) {
    return (RequestContext req, ResponseContext res) async {
      if (req.container.has<User>()) {
        var user = req.container.make<User>();
        _onLogout.add(user);
      }

      if (allowCookie == true) {
        res.cookies.removeWhere((cookie) => cookie.name == "token");
        _addProtectedCookie(res, 'token', '""');
      }

      if (options != null &&
          options.successRedirect != null &&
          options.successRedirect.isNotEmpty) {
        await res.redirect(options.successRedirect);
      }

      return true;
    };
  }
}

class _AuthResult<User> {
  final User user;
  final AuthToken token;

  _AuthResult(this.user, this.token);
}
