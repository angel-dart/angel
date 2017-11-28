library angel_route.src.router;

import 'package:combinator/combinator.dart';
import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';
import 'routing_exception.dart';
import '../string_util.dart';
part 'grammar.dart';
part 'symlink_route.dart';
part 'route.dart';
part 'routing_result.dart';

final RegExp _param = new RegExp(r':([A-Za-z0-9_]+)(\((.+)\))?');
final RegExp _rgxEnd = new RegExp(r'\$+$');
final RegExp _rgxStart = new RegExp(r'^\^+');
final RegExp _rgxStraySlashes =
    new RegExp(r'(^((\\+/)|(/))+)|(((\\+/)|(/))+$)');
final RegExp _slashDollar = new RegExp(r'/+\$');
final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// An abstraction over complex [Route] trees. Use this instead of the raw API. :)
class Router {
  final Map<String, Iterable<RoutingResult>> _cache = {};
  //final List<_ChainedRouter> _chained = [];
  final List _middleware = [];
  final Map<Pattern, Router> _mounted = {};
  final List<Route> _routes = [];
  bool _useCache = false;

  /// Set to `true` to print verbose debug output when interacting with this route.
  bool debug = false;

  List get middleware => new List.unmodifiable(_middleware);

  Map<Pattern, Router> get mounted =>
      new Map<Pattern, Router>.unmodifiable(_mounted);

  /// Additional filters to be run on designated requests.
  Map<String, dynamic> requestMiddleware = {};

  List<Route> get routes {
    return _routes.fold<List<Route>>([], (out, route) {
      if (route is SymlinkRoute) {
        var childRoutes = route.router.routes.fold<List<Route>>([], (out, r) {
          return out
            ..add(
              route.path.isEmpty ? r : new Route.join(route, r),
            );
        });

        return out..addAll(childRoutes);
      } else {
        return out..add(route);
      }
    });
  }

  /// Provide a `root` to make this Router revolve around a pre-defined route.
  /// Not recommended.
  Router({this.debug: false});

  /// Enables the use of a cache to eliminate the overhead of consecutive resolutions of the same path.
  void enableCache() {
    _useCache = true;
  }

  /// Adds a route that responds to the given path
  /// for requests with the given method (case-insensitive).
  /// Provide '*' as the method to respond to all methods.
  Route addRoute(String method, String path, Object handler,
      {List middleware: const []}) {
    if (_useCache == true)
      throw new StateError('Cannot add routes after caching is enabled.');

    // Check if any mounted routers can match this
    final handlers = [handler];

    if (middleware != null) handlers.insertAll(0, middleware);

    final route = new Route(path, method: method, handlers: handlers);
    _routes.add(route);
    return route;
  }

  /// Prepends the given middleware to any routes created
  /// by the resulting router.
  ///
  /// [middleware] can be either an `Iterable`, or a single object.
  ///
  /// The resulting router can be chained, too.
  _ChainedRouter chain(middleware) {
    var piped = new _ChainedRouter(this, middleware);
    var route = new SymlinkRoute('/', piped);
    _routes.add(route);
    return piped;
  }

  /// Returns a [Router] with a duplicated version of this tree.
  Router clone() {
    final router = new Router(debug: debug);
    final newMounted = new Map<Pattern, Router>.from(mounted);

    for (Route route in routes) {
      if (route is! SymlinkRoute) {
        router._routes.add(route.clone());
      } else if (route is SymlinkRoute) {
        final newRouter = route.router.clone();
        newMounted[route.path] = newRouter;
        final symlink = new SymlinkRoute(route.path, newRouter);
        router._routes.add(symlink);
      }
    }

    return router.._mounted.addAll(newMounted);
  }

  /// Creates a visual representation of the route hierarchy and
  /// passes it to a callback. If none is provided, `print` is called.
  void dumpTree(
      {callback(String tree),
      String header: 'Dumping route tree:',
      String tab: '  '}) {
    final buf = new StringBuffer();
    int tabs = 0;

    if (header != null && header.isNotEmpty) {
      buf.writeln(header);
    }

    buf.writeln('<root>');

    indent() {
      for (int i = 0; i < tabs; i++) buf.write(tab);
    }

    dumpRouter(Router router) {
      indent();
      tabs++;

      for (Route route in router.routes) {
        indent();
        buf.write('- ');
        if (route is! SymlinkRoute) buf.write('${route.method} ');
        buf.write('${route.path.isNotEmpty ? route.path : '/'}');

        if (route is SymlinkRoute) {
          buf.writeln();
          dumpRouter(route.router);
        } else {
          buf.writeln(' => ${route.handlers.length} handler(s)');
        }
      }

      tabs--;
    }

    dumpRouter(this);

    (callback ?? print)(buf.toString());
  }

  /// Creates a route, and allows you to add child routes to it
  /// via a [Router] instance.
  ///
  /// Returns the created route.
  /// You can also register middleware within the router.
  SymlinkRoute group(String path, void callback(Router router),
      {Iterable middleware: const [],
      String name: null,
      String namespace: null}) {
    final router = new Router().._middleware.addAll(middleware);
    callback(router..debug = debug);
    return mount(path, router, namespace: namespace)..name = name;
  }

  /// Generates a URI string based on the given input.
  /// Handy when you have named routes.
  ///
  /// Each item in `linkParams` should be a [Route],
  /// `String` or `Map<String, dynamic>`.
  ///
  /// Strings should be route names, namespaces, or paths.
  /// Maps should be parameters, which will be filled
  /// into the previous route.
  ///
  /// Paths and segments should correspond to the way
  /// you declared them.
  ///
  /// For example, if you declared a route group on
  /// `'users/:id'`, it would not be resolved if you
  /// passed `'users'` in [linkParams].
  ///
  /// Leading and trailing slashes are automatically
  /// removed.
  ///
  /// Set [absolute] to `true` to insert a forward slash
  /// before the generated path.
  ///
  /// Example:
  /// ```dart
  /// router.navigate(['users/:id', {'id': '1337'}, 'profile']);
  /// ```
  String navigate(Iterable linkParams, {bool absolute: true}) {
    final List<String> segments = [];
    Router search = this;
    Route lastRoute;

    for (final param in linkParams) {
      bool resolved = false;

      if (param is String) {
        // Search by name
        for (Route route in search.routes) {
          if (route.name == param) {
            segments.add(route.path.replaceAll(_straySlashes, ''));
            lastRoute = route;

            if (route is SymlinkRoute) {
              search = route.router;
            }

            resolved = true;
            break;
          }
        }

        // Search by path
        if (!resolved) {
          var scanner = new SpanScanner(param.replaceAll(_straySlashes, ''));
          for (Route route in search.routes) {
            int pos = scanner.position;
            if (route.parser.parse(scanner).successful && scanner.isDone) {
              segments.add(route.path.replaceAll(_straySlashes, ''));
              lastRoute = route;

              if (route is SymlinkRoute) {
                search = route.router;
              }

              resolved = true;
              break;
            } else
              scanner.position = pos;
          }
        }

        if (!resolved) {
          throw new RoutingException(
              'Cannot resolve route for link param "$param".');
        }
      } else if (param is Route) {
        segments.add(param.path.replaceAll(_straySlashes, ''));
      } else if (param is Map<String, dynamic>) {
        if (lastRoute == null) {
          throw new RoutingException(
              'Maps in link params must be preceded by a Route or String.');
        } else {
          segments.removeLast();
          segments.add(lastRoute.makeUri(param).replaceAll(_straySlashes, ''));
        }
      } else
        throw new RoutingException(
            'Link param $param is not Route, String, or Map<String, dynamic>.');
    }

    return absolute
        ? '/${segments.join('/').replaceAll(_straySlashes, '')}'
        : segments.join('/');
  }

  /// Manually assign via [requestMiddleware] instead.
  @deprecated
  registerMiddleware(String name, middleware) {
    requestMiddleware[name] = middleware;
  }

  /// Finds the first [Route] that matches the given path,
  /// with the given method.
  bool resolve(String absolute, String relative, List<RoutingResult> out,
      {String method: 'GET', bool strip: true}) {
    final cleanRelative =
        strip == false ? relative : stripStraySlashes(relative);
    var scanner = new SpanScanner(cleanRelative);

    bool crawl(Router r) {
      bool success = false;

      for (Route route in r.routes) {
        int pos = scanner.position;

        if (route is SymlinkRoute) {
          if (route.parser.parse(scanner).successful) {
            var s = crawl(route.router);
            if (s) success = true;
          }

          scanner.position = pos;
        } else if (route.method == '*' || route.method == method) {
          var parseResult = route.parser.parse(scanner);

          if (parseResult.successful && scanner.isDone) {
            var result = new RoutingResult(
                parseResult: parseResult,
                params: parseResult.value,
                shallowRoute: route,
                shallowRouter: this);
            out.add(result);
            success = true;
          }

          scanner.position = pos;
        }
      }

      return success;
    }

    return crawl(this);
  }

  /// Returns the result of [resolve] with [path] passed as
  /// both `absolute` and `relative`.
  Iterable<RoutingResult> resolveAbsolute(String path,
          {String method: 'GET', bool strip: true}) =>
      resolveAll(path, path, method: method, strip: strip);

  /// Finds every possible [Route] that matches the given path,
  /// with the given method.
  Iterable<RoutingResult> resolveAll(String absolute, String relative,
      {String method: 'GET', bool strip: true}) {
    if (_useCache == true) {
      return _cache.putIfAbsent('$method$absolute',
          () => _resolveAll(absolute, relative, method: method, strip: strip));
    }

    return _resolveAll(absolute, relative, method: method, strip: strip);
  }

  Iterable<RoutingResult> _resolveAll(String absolute, String relative,
      {String method: 'GET', bool strip: true}) {
    final List<RoutingResult> results = [];
    resolve(absolute, relative, results, method: method, strip: strip);

    // _printDebug(
    //    'Results of $method "/${absolute.replaceAll(_straySlashes, '')}": ${results.map((r) => r.route).toList()}');
    return results;
  }

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
  SymlinkRoute mount(String path, Router router,
      {bool hooked: true, String namespace: null}) {
    // Let's copy middleware, heeding the optional middleware namespace.
    String middlewarePrefix = namespace != null ? "$namespace." : "";

    Map copiedMiddleware = new Map.from(router.requestMiddleware);
    for (String middlewareName in copiedMiddleware.keys) {
      requestMiddleware["$middlewarePrefix$middlewareName"] =
          copiedMiddleware[middlewareName];
    }

    final route = new SymlinkRoute(path, router);
    _mounted[route.path] = router;
    _routes.add(route);
    //route._head = new RegExp(route.matcher.pattern.replaceAll(_rgxEnd, ''));

    return route..name = namespace;
  }

  /// Adds a route that responds to any request matching the given path.
  Route all(String path, Object handler, {List middleware}) {
    return addRoute('*', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a DELETE request.
  Route delete(String path, Object handler, {List middleware}) {
    return addRoute('DELETE', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a GET request.
  Route get(String path, Object handler, {List middleware}) {
    return addRoute('GET', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a HEAD request.
  Route head(String path, Object handler, {List middleware}) {
    return addRoute('HEAD', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a OPTIONS request.
  Route options(String path, Object handler, {List middleware}) {
    return addRoute('OPTIONS', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a POST request.
  Route post(String path, Object handler, {List middleware}) {
    return addRoute('POST', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a PATCH request.
  Route patch(String path, Object handler, {List middleware}) {
    return addRoute('PATCH', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a PUT request.
  Route put(String path, Object handler, {List middleware}) {
    return addRoute('PUT', path, handler, middleware: middleware);
  }
}

class _ChainedRouter extends Router {
  final List _handlers = [];
  Router _root;

  _ChainedRouter.empty();

  _ChainedRouter(Router root, middleware) {
    this._root = root;
    _handlers.addAll(middleware is Iterable ? middleware : [middleware]);
  }

  @override
  Route addRoute(String method, String path, handler,
      {List middleware: const []}) {
    var route = super.addRoute(method, path, handler,
        middleware: []..addAll(_handlers)..addAll(middleware ?? []));
    //_root._routes.add(route);
    return route;
  }

  SymlinkRoute group(String path, void callback(Router router),
      {Iterable middleware: const [],
      String name: null,
      String namespace: null}) {
    final router =
        new _ChainedRouter(_root, []..addAll(_handlers)..addAll(middleware));
    callback(router..debug = debug);
    return mount(path, router, namespace: namespace)..name = name;
  }

  @override
  SymlinkRoute mount(String path, Router router,
      {bool hooked: true, String namespace: null}) {
    final route =
        super.mount(path, router, hooked: hooked, namespace: namespace);
    route.router._middleware.insertAll(0, _handlers);
    //_root._routes.add(route);
    return route;
  }

  @override
  _ChainedRouter chain(middleware) {
    final piped = new _ChainedRouter.empty().._root = _root;
    piped._handlers.addAll([]
      ..addAll(_handlers)
      ..addAll(middleware is Iterable ? middleware : [middleware]));
    var route = new SymlinkRoute('/', piped);
    _routes.add(route);
    return piped;
  }
}

/// Optimizes a router by condensing all its routes into one level.
Router flatten(Router router) {
  var flattened = new Router(debug: router.debug == true)
    ..requestMiddleware.addAll(router.requestMiddleware);

  for (var route in router.routes) {
    if (route is SymlinkRoute) {
      var base = route.path.replaceAll(_straySlashes, '');
      var child = flatten(route.router);
      flattened.requestMiddleware.addAll(child.requestMiddleware);

      for (var route in child.routes) {
        var path = route.path.replaceAll(_straySlashes, '');
        var joined = '$base/$path'.replaceAll(_straySlashes, '');
        flattened.addRoute(route.method, joined.replaceAll(_straySlashes, ''),
            route.handlers.last,
            middleware:
                route.handlers.take(route.handlers.length - 1).toList());
      }
    } else {
      flattened.addRoute(route.method, route.path, route.handlers.last,
          middleware: route.handlers.take(route.handlers.length - 1).toList());
    }
  }

  return flattened..enableCache();
}
