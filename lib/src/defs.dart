import 'dart:async';

/// Serializes a user to the session.
typedef FutureOr UserSerializer<T>(T user);

/// Deserializes a user from the session.
typedef FutureOr<T> UserDeserializer<T>(userId);
