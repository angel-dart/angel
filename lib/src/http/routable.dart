part of angel_framework.http;

/// A routable server that can handle dynamic requests.
class Routable {
  /// Additional filters to be run on designated requests.
  Map <String, Object> middleware = {};

  /// Dynamic request paths that this server will respond to.
  Map <Route, Object> routes = {};
}