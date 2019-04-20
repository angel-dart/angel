import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:uuid/uuid.dart';

final Uuid _uuid = Uuid();

/// Ensures that the request contains a correct CSRF token.
///
/// For `POST` methods, or anything requiring, provide [parseBody] as `true`.
///
/// Note that this is useless without [setCsrfToken]. If no [name] is present in the
/// session, clients will pass through.
RequestHandler verifyCsrfToken(
    {bool allowCookie = false,
    bool allowQuery = true,
    bool parseBody = false,
    String name = 'csrf_token'}) {
  return (RequestContext req, res) async {
    if (!req.session.containsKey(name)) {
      throw AngelHttpException.forbidden(
          message: 'You cannot access this resource without a CSRF token.');
    }

    String csrfToken;
    if (parseBody) {
      await req.parseBody();
    }

    if (allowQuery && req.queryParameters.containsKey(name))
      csrfToken = req.queryParameters[name];
    else if (req.hasParsedBody && req.bodyAsMap.containsKey(name))
      csrfToken = req.bodyAsMap[name];
    else if (allowCookie) {
      var cookie =
          req.cookies.firstWhere((c) => c.name == name, orElse: () => null);
      if (cookie != null) csrfToken = cookie.value;
    }

    if (csrfToken == null)
      throw AngelHttpException.badRequest(message: 'Missing CSRF token.');

    String correctToken = req.session[name];

    if (csrfToken != correctToken)
      throw AngelHttpException.badRequest(message: 'Invalid CSRF token.');

    return true;
  };
}

/// Adds a CSRF token to the session, if none is present.
RequestHandler setCsrfToken({String name = 'csrf_token', bool cookie = false}) {
  return (RequestContext req, res) async {
    if (!req.session.containsKey(name)) req.session[name] = _uuid.v4();
    if (cookie) res.cookies.add(Cookie(name, req.session[name]));
    return true;
  };
}
