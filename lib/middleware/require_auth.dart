part of angel_auth;

/// Restricts access to a resource via authentication.
Future<bool> requireAuth(RequestContext req, ResponseContext res,
    {bool throws: true}) async {
  if (req.session.containsKey('userId'))
    return true;
  else if (throws) throw new AngelHttpException.NotAuthenticated();
  else return false;
}