import 'dart:async';

/// Serializes a user to the session.
typedef Future UserSerializer(user);

/// Deserializes a user from the session.
typedef Future UserDeserializer(userId);