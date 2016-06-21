part of angel_framework.http;

/// Supports accessing members of a Map as though they were actual members.
class Extensible {
  /// A set of custom properties that can be assigned to the server.
  ///
  /// Useful for configuration and extension.
  Map properties = {};

  noSuchMethod(Invocation invocation) {
    if (invocation.memberName != null) {
      String name = MirrorSystem.getName(invocation.memberName);
      if (properties.containsKey(name)) {
        if (invocation.isGetter)
          return properties[name];
        else if (invocation.isMethod) {
          return Function.apply(
              properties[name], invocation.positionalArguments,
              invocation.namedArguments);
        }
      }
    }

    super.noSuchMethod(invocation);
  }
}