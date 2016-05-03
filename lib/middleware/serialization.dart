part of angel_auth;

/// Serializes a user to the session.
typedef Future UserSerializer(user);

/// Deserializes a user from the session.
typedef Future UserDeserializer(userId);

_serializationMiddleware(RequestContext req, ResponseContext res) async {
  if (await requireAuth(req, res, throws: false)) {
    req.properties['user'] = await Auth.deserializer(req.session['userId']);
  }

  return true;
}