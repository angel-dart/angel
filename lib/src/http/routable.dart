part of angel_framework.http;

typedef RouteAssigner(Pattern path, handler, {List middleware});

/// A routable server that can handle dynamic requests.
class Routable {
  /// Additional filters to be run on designated requests.
  Map <String, Middleware> middleware = {};

  /// Dynamic request paths that this server will respond to.
  List<Route> routes = [];

  /// A set of [Service] objects that have been mapped into routes.
  Map <Pattern, Service> services = {};

  _makeRouteAssigner(String method) {
    return (Pattern path, Object handler, {List middleware}) {
      var route = new Route(method, path, (middleware ?? [])
        ..add(handler));
      routes.add(route);
    };
  }

  /// Assigns a middleware to a name for convenience.
  registerMiddleware(String name, Middleware middleware) {
    this.middleware[name] = middleware;
  }

  /// Retrieves the service assigned to the given path.
  Service service(Pattern path) => services[path];

  /// Incorporates another routable's routes into this one's.
  use(Pattern path, Routable routable) {
    middleware.addAll(routable.middleware);
    for (Route route in routable.routes) {
      Route provisional = new Route('', path);
      route.matcher = new RegExp(route.matcher.pattern.replaceAll(
          new RegExp('^\\^'),
          provisional.matcher.pattern.replaceAll(new RegExp(r'\$$'), '')));
      route.path = "$path${route.path}";

      routes.add(route);
    }

    if (routable is Service) {
      services[path.toString()] = routable;
    }
  }

  RouteAssigner get, post, patch, delete;

  Routable() {
    this.get = _makeRouteAssigner('GET');
    this.post = _makeRouteAssigner('POST');
    this.patch = _makeRouteAssigner('PATCH');
    this.delete = _makeRouteAssigner('DELETE');
  }

}