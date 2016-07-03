part of angel_auth;

/// Restricts access to a resource via authentication.
Future<bool> requireAuth(RequestContext req, ResponseContext res,
    {bool throws: true}) async {
  if (req.session.containsKey('userId'))
    return true;
  else if (throws) {
    res.status(HttpStatus.UNAUTHORIZED);
    throw new AngelHttpException.Forbidden();
  }
  else return false;
}