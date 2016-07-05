part of angel_framework.http;

typedef Route RouteAssigner(Pattern path, handler, {List middleware});

_matchingAnnotation(List<InstanceMirror> metadata, Type T) {
  for (InstanceMirror metaDatum in metadata) {
    if (metaDatum.hasReflectee) {
      var reflectee = metaDatum.reflectee;
      if (reflectee.runtimeType == T) {
        return reflectee;
      }
    }
  }
  return null;
}

_getAnnotation(obj, Type T) {
  if (obj is Function || obj is Future) {
    MethodMirror methodMirror = (reflect(obj) as ClosureMirror).function;
    return _matchingAnnotation(methodMirror.metadata, T);
  } else {
    ClassMirror classMirror = reflectClass(obj.runtimeType);
    return _matchingAnnotation(classMirror.metadata, T);
  }

  return null;
}

/// A routable server that can handle dynamic requests.
class Routable extends Extensible {
  /// Additional filters to be run on designated requests.
  Map <String, RequestMiddleware> requestMiddleware = {};

  /// Dynamic request paths that this server will respond to.
  List<Route> routes = [];

  /// A set of [Service] objects that have been mapped into routes.
  Map <Pattern, Service> services = {};

  /// A set of [Controller] objects that have been loaded into the application.
  Map<String, Controller> controllers = {};

  StreamController<Service> _onService = new StreamController<Service>.broadcast();

  /// Fired whenever a service is added to this instance.
  ///
  /// **NOTE**: This is a broadcast stream.
  Stream<Service> get onService => _onService.stream;

  /// Assigns a middleware to a name for convenience.
  registerMiddleware(String name, RequestMiddleware middleware) {
    this.requestMiddleware[name] = middleware;
  }

  /// Retrieves the service assigned to the given path.
  Service service(Pattern path) => services[path];

  /// Retrieves the controller with the given name.
  Controller controller(String name) => controllers[name];

  /// Incorporates another [Routable]'s routes into this one's.
  ///
  /// If `hooked` is set to `true` and a [Service] is provided,
  /// then that service will be wired to a [HookedService] proxy.
  /// If a `middlewareNamespace` is provided, then any middleware
  /// from the provided [Routable] will be prefixed by that namespace,
  /// with a dot.
  /// For example, if the [Routable] has a middleware 'y', and the `middlewareNamespace`
  /// is 'x', then that middleware will be available as 'x.y' in the main application.
  /// These namespaces can be nested.
  void use(Pattern path, Routable routable,
      {bool hooked: true, String middlewareNamespace: null}) {
    Routable _routable = routable;

    // If we need to hook this service, do it here. It has to be first, or
    // else all routes will point to the old service.
    if (_routable is Service) {
      Hooked hookedDeclaration = _getAnnotation(_routable, Hooked);
      Service service = (hookedDeclaration != null || hooked)
          ? new HookedService(_routable)
          : _routable;
      services[path.toString().trim().replaceAll(
          new RegExp(r'(^\/+)|(\/+$)'), '')] = service;
      _routable = service;
    }

    if (_routable is Angel) {
      all(path, (RequestContext req, ResponseContext res) async {
        req.app = _routable;
        res.app = _routable;
        return true;
      });
    }

    for (Route route in _routable.routes) {
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

    // Let's copy middleware, heeding the optional middleware namespace.
    String middlewarePrefix = "";
    if (middlewareNamespace != null)
      middlewarePrefix = "$middlewareNamespace.";

    for (String middlewareName in _routable.requestMiddleware.keys) {
      requestMiddleware["$middlewarePrefix$middlewareName"] =
      _routable.requestMiddleware[middlewareName];
    }

    // Copy services, too. :)
    for (Pattern servicePath in _routable.services.keys) {
      String newServicePath = path.toString().trim().replaceAll(
          new RegExp(r'(^\/+)|(\/+$)'), '') + '/$servicePath';
      services[newServicePath] = _routable.services[servicePath];
    }

    if (routable is Service)
      _onService.add(routable);
  }

  /// Adds a route that responds to the given path
  /// for requests with the given method (case-insensitive).
  /// Provide '*' as the method to respond to all methods.
  Route addRoute(String method, Pattern path, Object handler,
      {List middleware}) {
    List handlers = [];

    // Merge @Middleware declaration, if any
    Middleware middlewareDeclaration = _getAnnotation(
        handler, Middleware);
    if (middlewareDeclaration != null) {
      handlers.addAll(middlewareDeclaration.handlers);
    }

    handlers
      ..addAll(middleware ?? [])
      ..add(handler);
    var route = new Route(method.toUpperCase().trim(), path, handlers);
    routes.add(route);
    return route;
  }

  /// Adds a route that responds to any request matching the given path.
  Route all(Pattern path, Object handler, {List middleware}) {
    return addRoute('*', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a GET request.
  Route get(Pattern path, Object handler, {List middleware}) {
    return addRoute('GET', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a POST request.
  Route post(Pattern path, Object handler, {List middleware}) {
    return addRoute('POST', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a PATCH request.
  Route patch(Pattern path, Object handler, {List middleware}) {
    return addRoute('PATCH', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a DELETE request.
  Route delete(Pattern path, Object handler, {List middleware}) {
    return addRoute('DELETE', path, handler, middleware: middleware);
  }

  Routable() {
  }

}