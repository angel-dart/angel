abstract class RoutingException extends Exception {
  factory RoutingException(String message) => new _RoutingExceptionImpl(message);
  factory RoutingException.orphan() => new _RoutingExceptionImpl("Tried to resolve path '..' on a route that has no parent.");
  factory RoutingException.noSuchRoute(String path) => new _RoutingExceptionImpl("Tried to navigate to non-existent route: '$path'.");
}

class _RoutingExceptionImpl implements RoutingException {
  final String message;

  _RoutingExceptionImpl(this.message);

  @override
  String toString() => message;
}