library angel_route.src.router;

import 'package:combinator/combinator.dart';
import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

import '../string_util.dart';
import 'routing_exception.dart';

part 'grammar.dart';

part 'route.dart';

part 'routing_result.dart';

part 'symlink_route.dart';

//final RegExp _param = new RegExp(r':([A-Za-z0-9_]+)(\((.+)\))?');
//final RegExp _rgxEnd = new RegExp(r'\$+$');
//final RegExp _rgxStart = new RegExp(r'^\^+');
//final RegExp _rgxStraySlashes =
//    new RegExp(r'(^((\\+/)|(/))+)|(((\\+/)|(/))+$)');
//final RegExp _slashDollar = new RegExp(r'/+\$');
final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// An abstraction over complex [Route] trees. Use this instead of the raw API. :)
class Router<T> {
  final Map<String, Iterable<RoutingResult<T>>> _cache = {};

  //final List<_ChainedRouter> _chained = [];
  final List<T> _middleware = [];
  final Map<Pattern, Router<T>> _mounted = {};
  final List<Route<T>> _routes = [];
  bool _useCache = false;

  List<T> get middleware => new List<T>.unmodifiable(_middleware);

  Map<Pattern, Router<T>> get mounted =>
      new Map<Pattern, Router<T>>.unmodifiable(_mounted);

  List<Route<T>> get routes {
    return _routes.fold<List<Route<T>>>([], (out, route) {
      if (route is SymlinkRoute<T>) {
        var childRoutes =
            route.router.routes.fold<List<Route<T>>>([], (out, r) {
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
  Router();

  /// Enables the use of a cache to eliminate the overhead of consecutive resolutions of the same path.
  void enableCache() {
    _useCache = true;
  }

  /// Adds a route that responds to the given path
  /// for requests with the given method (case-insensitive).
  /// Provide '*' as the method to respond to all methods.
  Route<T> addRoute(String method, String path, T handler,
      {Iterable<T> middleware}) {
    middleware ??= <T>[];
    if (_useCache == true)
      throw new StateError('Cannot add routes after caching is enabled.');

    // Check if any mounted routers can match this
    final handlers = <T>[handler];

    if (middleware != null) handlers.insertAll(0, middleware);

    final route = new Route<T>(path, method: method, handlers: handlers);
    _routes.add(route);
    return route;
  }

  /// Prepends the given [middleware] to any routes created
  /// by the resulting router.
  ///
  /// The resulting router can be chained, too.
  _ChainedRouter<T> chain(Iterable<T> middleware) {
    var piped = new _ChainedRouter<T>(this, middleware);
    var route = new SymlinkRoute<T>('/', piped);
    _routes.add(route);
    return piped;
  }

  /// Returns a [Router] with a duplicated version of this tree.
  Router<T> clone() {
    final router = new Router<T>();
    final newMounted = new Map<Pattern, Router<T>>.from(mounted);

    for (var route in routes) {
      if (route is! SymlinkRoute<T>) {
        router._routes.add(route.clone());
      } else if (route is SymlinkRoute<T>) {
        final newRouter = route.router.clone();
        newMounted[route.path] = newRouter;
        final symlink = new SymlinkRoute<T>(route.path, newRouter);
        router._routes.add(symlink);
      }
    }

    return router.._mounted.addAll(newMounted);
  }

  /// Creates a visual representation of the route hierarchy and
  /// passes it to a callback. If none is provided, `print` is called.
  void dumpTree(
      {callback(String tree),
      String header = 'Dumping route tree:',
      String tab = '  '}) {
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

        if (route is SymlinkRoute<T>) {
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
  SymlinkRoute<T> group(String path, void callback(Router<T> router),
      {Iterable<T> middleware, String name}) {
    middleware ??= <T>[];
    final router = new Router<T>().._middleware.addAll(middleware);
    callback(router);
    return mount(path, router)..name = name;
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
  String navigate(Iterable linkParams, {bool absolute = true}) {
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

            if (route is SymlinkRoute<T>) {
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

              if (route is SymlinkRoute<T>) {
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

  /// Finds the first [Route] that matches the given path,
  /// with the given method.
  bool resolve(String absolute, String relative, List<RoutingResult<T>> out,
      {String method = 'GET', bool strip = true}) {
    final cleanRelative =
        strip == false ? relative : stripStraySlashes(relative);
    var scanner = new SpanScanner(cleanRelative);

    bool crawl(Router<T> r) {
      bool success = false;

      for (var route in r.routes) {
        int pos = scanner.position;

        if (route is SymlinkRoute<T>) {
          if (route.parser.parse(scanner).successful) {
            var s = crawl(route.router);
            if (s) success = true;
          }

          scanner.position = pos;
        } else if (route.method == '*' || route.method == method) {
          var parseResult = route.parser.parse(scanner);

          if (parseResult.successful && scanner.isDone) {
            var result = new RoutingResult<T>(
                parseResult: parseResult,
                params: parseResult.value.params,
                shallowRoute: route,
                shallowRouter: this,
                tail: (parseResult.value.tail ?? '') + scanner.rest);
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
  Iterable<RoutingResult<T>> resolveAbsolute(String path,
          {String method = 'GET', bool strip = true}) =>
      resolveAll(path, path, method: method, strip: strip);

  /// Finds every possible [Route] that matches the given path,
  /// with the given method.
  Iterable<RoutingResult<T>> resolveAll(String absolute, String relative,
      {String method = 'GET', bool strip = true}) {
    if (_useCache == true) {
      return _cache.putIfAbsent('$method$absolute',
          () => _resolveAll(absolute, relative, method: method, strip: strip));
    }

    return _resolveAll(absolute, relative, method: method, strip: strip);
  }

  Iterable<RoutingResult<T>> _resolveAll(String absolute, String relative,
      {String method = 'GET', bool strip = true}) {
    var results = <RoutingResult<T>>[];
    resolve(absolute, relative, results, method: method, strip: strip);

    // _printDebug(
    //    'Results of $method "/${absolute.replaceAll(_straySlashes, '')}": ${results.map((r) => r.route).toList()}');
    return results;
  }

  /// Incorporates another [Router]'s routes into this one's.
  SymlinkRoute<T> mount(String path, Router<T> router) {
    final route = new SymlinkRoute<T>(path, router);
    _mounted[route.path] = router;
    _routes.add(route);
    //route._head = new RegExp(route.matcher.pattern.replaceAll(_rgxEnd, ''));

    return route;
  }

  /// Adds a route that responds to any request matching the given path.
  Route<T> all(String path, T handler, {Iterable<T> middleware}) {
    return addRoute('*', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a DELETE request.
  Route<T> delete(String path, T handler, {Iterable<T> middleware}) {
    return addRoute('DELETE', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a GET request.
  Route<T> get(String path, T handler, {Iterable<T> middleware}) {
    return addRoute('GET', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a HEAD request.
  Route<T> head(String path, T handler, {Iterable<T> middleware}) {
    return addRoute('HEAD', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a OPTIONS request.
  Route<T> options(String path, T handler, {Iterable<T> middleware}) {
    return addRoute('OPTIONS', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a POST request.
  Route<T> post(String path, T handler, {Iterable<T> middleware}) {
    return addRoute('POST', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a PATCH request.
  Route<T> patch(String path, T handler, {Iterable<T> middleware}) {
    return addRoute('PATCH', path, handler, middleware: middleware);
  }

  /// Adds a route that responds to a PUT request.
  Route put(String path, T handler, {Iterable<T> middleware}) {
    return addRoute('PUT', path, handler, middleware: middleware);
  }
}

class _ChainedRouter<T> extends Router<T> {
  final List<T> _handlers = <T>[];
  Router _root;

  _ChainedRouter.empty();

  _ChainedRouter(Router root, Iterable<T> middleware) {
    this._root = root;
    _handlers.addAll(middleware);
  }

  @override
  Route<T> addRoute(String method, String path, handler,
      {Iterable<T> middleware}) {
    var route = super.addRoute(method, path, handler,
        middleware: []..addAll(_handlers)..addAll(middleware ?? []));
    //_root._routes.add(route);
    return route;
  }

  @override
  SymlinkRoute<T> group(String path, void callback(Router<T> router),
      {Iterable<T> middleware, String name}) {
    final router = new _ChainedRouter<T>(
        _root, []..addAll(_handlers)..addAll(middleware ?? []));
    callback(router);
    return mount(path, router)..name = name;
  }

  @override
  SymlinkRoute<T> mount(String path, Router<T> router) {
    final route = super.mount(path, router);
    route.router._middleware.insertAll(0, _handlers);
    //_root._routes.add(route);
    return route;
  }

  @override
  _ChainedRouter<T> chain(Iterable<T> middleware) {
    final piped = new _ChainedRouter<T>.empty().._root = _root;
    piped._handlers.addAll([]..addAll(_handlers)..addAll(middleware));
    var route = new SymlinkRoute<T>('/', piped);
    _routes.add(route);
    return piped;
  }
}

/// Optimizes a router by condensing all its routes into one level.
Router<T> flatten<T>(Router<T> router) {
  var flattened = new Router<T>();

  for (var route in router.routes) {
    if (route is SymlinkRoute<T>) {
      var base = route.path.replaceAll(_straySlashes, '');
      var child = flatten(route.router);

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
