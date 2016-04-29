part of angel_framework.http;

typedef Route RouteAssigner(Pattern path, handler, {List middleware});

/// A routable server that can handle dynamic requests.
class Routable extends Extensible {
  /// Additional filters to be run on designated requests.
  Map <String, Middleware> middleware = {};

  /// Dynamic request paths that this server will respond to.
  List<Route> routes = [];

  /// A set of [Service] objects that have been mapped into routes.
  Map <Pattern, Service> services = {};

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
      if (route.path == '/') {
        route.path = '';
        route.matcher = new RegExp(r'^\/?$');
      }
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

  /// Adds a route that responds to the given path
  /// for requests with the given method (case-insensitive).
  /// Provide '*' as the method to respond to all methods.
  addRoute(String method, Pattern path, Object handler, {List middleware}) {
    var route = new Route(method.toUpperCase().trim(), path, (middleware ?? [])
      ..add(handler));
    routes.add(route);
    return route;
  }

  /// Adds a route that responds to any request matching the given path.
  all(Pattern path, Object handler, {List middleware}) {
    return addRoute('*', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a GET request.
  get(Pattern path, Object handler, {List middleware}) {
    return addRoute('GET', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a POST request.
  post(Pattern path, Object handler, {List middleware}) {
    return addRoute('POST', path, handler, middleware: middleware);
  }
  
  /// Adds a route that responds to a PATCH request.
  patch(Pattern path, Object handler, {List middleware}) {
    return addRoute('PATCH', path, handler, middleware: middleware);
  }
  
  /// Adds a route that responds to a DELETE request.
  delete(Pattern path, Object handler, {List middleware}) {
    return addRoute('DELETE', path, handler, middleware: middleware);
  }

  Routable() {
  }

}