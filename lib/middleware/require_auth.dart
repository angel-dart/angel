part of angel_auth;

/// Restricts access to a resource via authentication.
Future<bool> requireAuth(RequestContext req, ResponseContext res,
    {bool throws: true}) async {
  reject() {
    if (throws) {
      res.status(HttpStatus.UNAUTHORIZED);
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
    if (split.length != 3) return reject();

    Map header = JSON.decode(UTF8.decode(BASE64URL.decode(split[0])));

    if (header['typ'] != "JWT" || header['alg'] != "HS256") return reject();

    Map payload = JSON.decode(UTF8.decode(BASE64URL.decode(split[1])));
  } else
    return reject();
}
