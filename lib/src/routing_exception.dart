/// Represents an error in route configuration or navigation.
abstract class RoutingException extends Exception {
  factory RoutingException(String message) => _RoutingExceptionImpl(message);

  /// Occurs when trying to resolve the parent of a [Route] without a parent.
  factory RoutingException.orphan() => _RoutingExceptionImpl(
      "Tried to resolve path '..' on a route that has no parent.");

  /// Occurs when the user attempts to navigate to a non-existent route.
  factory RoutingException.noSuchRoute(String path) => _RoutingExceptionImpl(
      "Tried to navigate to non-existent route: '$path'.");
}

class _RoutingExceptionImpl implements RoutingException {
  final String message;

  _RoutingExceptionImpl(this.message);

  @override
  String toString() => message;
}
