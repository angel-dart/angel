import 'extensible.dart';
import 'route.dart';
import 'routing_exception.dart';

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// An abstraction over complex [Route] trees. Use this instead of the raw API. :)
class Router extends Extensible {
  /// Set to `true` to print verbose debug output when interacting with this route.
  bool debug = false;

  /// Additional filters to be run on designated requests.
  Map<String, dynamic> requestMiddleware = {};

  /// The single [Route] that serves as the root of the hierarchy.
  final Route root;

  /// Provide a `root` to make this Router revolve around a pre-defined route.
  /// Not recommended.
  Router([Route root]) : this.root = root ?? new _RootRoute();

  void _printDebug(msg) {
    if (debug)
      _printDebug(msg);
  }

  /// Adds a route that responds to the given path
  /// for requests with the given method (case-insensitive).
  /// Provide '*' as the method to respond to all methods.
  Route addRoute(String method, Pattern path, Object handler,
      {List middleware}) {
    List handlers = [];

    handlers
      ..addAll(middleware ?? [])
      ..add(handler);

    if (path is RegExp) {
      return root.child(path, handlers: handlers, method: method);
    } else if (path.toString().replaceAll(_straySlashes, '').isEmpty) {
      return root.child(path.toString(), handlers: handlers, method: method);
    } else {
      var segments = path
          .toString()
          .split('/')
          .where((str) => str.isNotEmpty)
          .toList(growable: false);
      Route result;

      if (segments.isEmpty) {
        return new Route('/', handlers: handlers, method: method);
      } else {
        _printDebug('Want ${segments[0]}');
        result = resolve(segments[0]);

        if (result != null) {
          if (segments.length > 1) {
            _printDebug('Resolved: ${result} for "${segments[0]}"');
            segments = segments.skip(1).toList(growable: false);

            Route existing;

            do {
              existing = result.resolve(segments[0]);

              if (existing != null) {
                result = existing;
              }
            } while (existing != null);
          } else throw new RoutingException("Cannot overwrite existing route '${segments[0]}'.");
        }
      }

      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];

        if (i == segments.length - 1) {
          if (result == null) {
            result = root.child(segment, handlers: handlers, method: method);
          } else {
            result = result.child(segment, handlers: handlers, method: method);
          }
        } else {
          if (result == null) {
            result = root.child(segment, method: "*");
          } else {
            result = result.child(segment, method: "*");
          }
        }
      }

      return result..debug = debug;
    }
  }

  /// Creates a visual representation of the route hierarchy and
  /// passes it to a callback. If none is provided, `print` is called.
  void dumpTree(
      {callback(String tree), header: 'Dumping route tree:', tab: '  '}) {
    var tabs = 0;
    final buf = new StringBuffer();

    void dumpRoute(Route route, {String replace: null}) {
      for (var i = 0; i < tabs; i++) buf.write(tab);

      if (route == root)
        buf.write('(root) ${route.method} ');
      else buf.write('- ${route.method} ');

      final p =
          replace != null ? route.path.replaceAll(replace, '') : route.path;

      if (p.isEmpty)
        buf.write("'/'");
      else
        buf.write("'${p.replaceAll(_straySlashes, '')}'");

      if (route.handlers.isNotEmpty)
        buf.writeln(' => ${route.handlers.length} handler(s)');
      else
        buf.writeln();

      tabs++;
      route.children.forEach((r) => dumpRoute(r, replace: route.path));
      tabs--;
    }

    if (header != null && header.isNotEmpty) buf.writeln(header);

    dumpRoute(root);
    (callback ?? print)(buf.toString());
  }

  /// Creates a route, and allows you to add child routes to it
  /// via a [Router] instance.
  ///
  /// Returns the created route.
  /// You can also register middleware within the router.
  Route group(Pattern path, void callback(Router router),
      {Iterable middleware: const [],
      String method: "*",
      String name: null,
      String namespace: null}) {
    final route =
        root.child(path, handlers: middleware, method: method, name: name);
    final router = new Router(route);
    callback(router);

    // Let's copy middleware, heeding the optional middleware namespace.
    String middlewarePrefix = namespace != null ? "$namespace." : "";

    Map copiedMiddleware = new Map.from(router.requestMiddleware);
    for (String middlewareName in copiedMiddleware.keys) {
      requestMiddleware["$middlewarePrefix$middlewareName"] =
          copiedMiddleware[middlewareName];
    }

    return route;
  }

  /// Assigns a middleware to a name for convenience.
  registerMiddleware(String name, middleware) {
    requestMiddleware[name] = middleware;
  }

  /// Finds the first [Route] that matches the given path.
  ///
  /// You can pass an additional filter to determine which
  /// routes count as matches.
  Route resolve(String path, [bool filter(Route route)]) =>
      root.resolve(path, filter: filter);

  /// Incorporates another [Router]'s routes into this one's.
  ///
  /// If `hooked` is set to `true` and a [Service] is provided,
  /// then that service will be wired to a [HookedService] proxy.
  /// If a `namespace` is provided, then any middleware
  /// from the provided [Router] will be prefixed by that namespace,
  /// with a dot.
  /// For example, if the [Router] has a middleware 'y', and the `namespace`
  /// is 'x', then that middleware will be available as 'x.y' in the main router.
  /// These namespaces can be nested.
  void use(Pattern path, Router router,
      {bool hooked: true, String namespace: null}) {
    // Let's copy middleware, heeding the optional middleware namespace.
    String middlewarePrefix = namespace != null ? "$namespace." : "";

    Map copiedMiddleware = new Map.from(router.requestMiddleware);
    for (String middlewareName in copiedMiddleware.keys) {
      requestMiddleware["$middlewarePrefix$middlewareName"] =
          copiedMiddleware[middlewareName];
    }

    root.child(path).addChild(router.root);
  }

  /// Adds a route that responds to any request matching the given path.
  Route all(Pattern path, Object handler, {List middleware}) {
    return addRoute('*', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a DELETE request.
  Route delete(Pattern path, Object handler, {List middleware}) {
    return addRoute('DELETE', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a GET request.
  Route get(Pattern path, Object handler, {List middleware}) {
    return addRoute('GET', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a HEAD request.
  Route head(Pattern path, Object handler, {List middleware}) {
    return addRoute('HEAD', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a OPTIONS request.
  Route options(Pattern path, Object handler, {List middleware}) {
    return addRoute('OPTIONS', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a POST request.
  Route post(Pattern path, Object handler, {List middleware}) {
    return addRoute('POST', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a PATCH request.
  Route patch(Pattern path, Object handler, {List middleware}) {
    return addRoute('PATCH', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a PUT request.
  Route put(Pattern path, Object handler, {List middleware}) {
    return addRoute('PUT', path, handler, middleware: middleware);
  }
}

class _RootRoute extends Route {
  _RootRoute():super("/", name: "<root>");


  @override
  String toString() => "ROOT";
}