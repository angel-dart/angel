library angel_route.src.router;

import 'extensible.dart';
import 'routing_exception.dart';

part 'route.dart';

final RegExp _param = new RegExp(r':([A-Za-z0-9_]+)(\((.+)\))?');
final RegExp _rgxEnd = new RegExp(r'\$+$');
final RegExp _rgxStart = new RegExp(r'^\^+');
final RegExp _rgxStraySlashes =
    new RegExp(r'(^((\\+/)|(/))+)|(((\\+/)|(/))+$)');
final RegExp _slashDollar = new RegExp(r'/+\$');
final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// An abstraction over complex [Route] trees. Use this instead of the raw API. :)
class Router extends Extensible {
  Route _root;

  /// Set to `true` to print verbose debug output when interacting with this route.
  bool debug = false;

  /// Additional filters to be run on designated requests.
  Map<String, dynamic> requestMiddleware = {};

  /// The single [Route] that serves as the root of the hierarchy.
  Route get root => _root;

  /// Provide a `root` to make this Router revolve around a pre-defined route.
  /// Not recommended.
  Router({this.debug: false, Route root}) {
    _root = (_root = root ?? new _RootRoute())..debug = debug;
  }

  void _printDebug(msg) {
    if (debug) print(msg);
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
      return root.child(path, debug: debug, handlers: handlers, method: method);
    } else {
      // if (path.toString().replaceAll(_straySlashes, '').isEmpty || true) {
      return root.child(path.toString(),
          debug: debug, handlers: handlers, method: method);
    }
    /* else {
      var segments = path
          .toString()
          .split('/')
          .where((str) => str.isNotEmpty)
          .toList(growable: false);
      Route result;

      if (segments.isEmpty) {
        return new Route('/', debug: debug, handlers: handlers, method: method)
          ..debug = debug;
      } else {
        result = resolveOnRoot(segments[0],
            filter: (route) => route.method == method || route.method == '*');

        if (result != null) {
          if (segments.length > 1) {
            _printDebug('Resolved: ${result} for "${segments[0]}"');
            segments = segments.skip(1).toList(growable: false);

            Route existing;

            do {
              existing = result.resolve(segments[0],
                  filter: (route) =>
                      route.method == method || route.method == '*');

              if (existing != null) {
                result = existing;
              }
            } while (existing != null);
          }
        }
      }

      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];

        if (i == segments.length - 1) {
          if (result == null) {
            result = root.child(segment,
                debug: debug, handlers: handlers, method: method);
          } else {
            result = result.child(segment,
                debug: debug, handlers: handlers, method: method);
          }
        } else {
          if (result == null) {
            result = root.child(segment, debug: debug, method: "*");
          } else {
            result = result.child(segment, debug: debug, method: "*");
          }
        }
      }

      return result..debug = debug;
    } */
  }

  /// Returns a [Router] with a duplicated version of this tree.
  Router clone({bool normalize: true}) {
    final router = new Router(debug: debug);

    _copy(Route route, Route parent) {
      final r = route.clone();
      parent._children.add(r.._parent = parent);

      route.children.forEach((child) => _copy(child, r));
    }

    root.children.forEach((child) => _copy(child, router.root));

    if (normalize) router.normalize();

    return router;
  }

  /// Creates a visual representation of the route hierarchy and
  /// passes it to a callback. If none is provided, `print` is called.
  void dumpTree(
      {callback(String tree),
      header: 'Dumping route tree:',
      tab: '  ',
      showMatchers: false}) {
    var tabs = 0;
    final buf = new StringBuffer();

    void dumpRoute(Route route, {Pattern replace: null}) {
      for (var i = 0; i < tabs; i++) buf.write(tab);

      if (route == root)
        buf.writeln('(root)');
      else {
        buf.write('- ${route.method} ');

        var p =
            replace != null ? route.path.replaceAll(replace, '') : route.path;
        p = p.replaceAll(_straySlashes, '');

        if (p.isEmpty)
          buf.write("'/'");
        else
          buf.write("'${p.replaceAll(_straySlashes, '')}'");

        if (showMatchers) {
          buf.write(' (matcher: ${route.matcher.pattern})');
        }

        if (route.handlers.isNotEmpty)
          buf.writeln(' => ${route.handlers.length} handler(s)');
        else
          buf.writeln();
      }

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
    final router = new Router(root: route);
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
  Route resolveOnRoot(String path, {bool filter(Route route)}) =>
      root.resolve(path, filter: filter);

  /// Finds the first [Route] that matches the given path,
  /// with the given method.
  Route resolve(String path, {String method: 'GET'}) {
    final String _path = path.replaceAll(_straySlashes, '');
    final segments = _path.split('/').where((str) => str.isNotEmpty);
    _printDebug('Segments: $segments');
    return _resolve(root, _path, method, segments.first, segments.skip(1));
  }

  /// Finds every possible [Route] that matches the given path,
  /// with the given method.
  ///
  /// This is preferable to [resolve].
  /// Keep in mind that this function uses either a [linearClone] or a [clone], and thus
  /// will not return the same exact routes from the original tree.
  Iterable<Route> resolveAll(String path,
      {bool linear: true, String method: 'GET', bool normalizeClone: true}) {
    final router = linear
        ? linearClone(normalize: normalizeClone)
        : clone(normalize: normalizeClone);
    final routes = [];
    var resolved = router.resolve(path, method: method);

    while (resolved != null) {
      routes.add(resolved);
      router.root._children.remove(resolved);

      resolved = router.resolve(path, method: method);
    }

    return routes.where((route) => route != null);
  }

  _validHead(RegExp rgx) {
    return !rgx.hasMatch('');
  }

  _resolve(Route ref, String fullPath, String method, String head,
      Iterable<String> tail) {
    _printDebug('$method $fullPath on $ref: head: $head, tail: ${tail.join(
            '/')}');

    // Does the index route match?
    if (ref.matcher.hasMatch(fullPath)) {
      final index = ref.indexRoute;

      for (Route child in ref.allIndices) {
        _printDebug('Possible index: $child');

        if (child == child.indexRoute && ['*', method].contains(child.method)) {
          _printDebug('Possible index was exact match: $child');
          return child;
        }

        final resolved = _resolve(child, fullPath, method, head, tail);

        if (resolved != null) {
          _printDebug('Resolved from possible index: $resolved');
          return resolved;
        } else
          _printDebug('Possible index returned null: $child');
      }

      if (['*', method].contains(index.method)) {
        return index;
      }
    } else {
      // Now, let's check if any route's head matches the
      // given head. If so, we try to resolve with that
      // given head. If so, we try to resolve with that
      // route, using a head corresponding to the one we
      // matched.
      for (Route child in ref.children) {
        if (child._head != null &&
            child._head.hasMatch(fullPath) &&
            _validHead(child._head)) {
          final newHead = child._head
              .firstMatch(fullPath)
              .group(0)
              .replaceAll(_straySlashes, '');
          final newTail = fullPath
              .replaceAll(child._head, '')
              .replaceAll(_straySlashes, '')
              .split('/')
              .where((str) => str.isNotEmpty);
          final resolved = _resolve(child, fullPath, method, newHead, newTail);

          if (resolved != null) {
            _printDebug(
                'Head match: $resolved from head: ${child._head.pattern}');
            return resolved;
          }
        } else if (child._head != null) {
          _printDebug(
              'Head ${child._head.pattern} on $child failed to match $fullPath');
        }
      }

      // Try to match children by full path
      for (Route child in ref.children) {
        if (child.matcher.hasMatch(fullPath)) {
          final resolved = _resolve(child, fullPath, method, head, tail);

          if (resolved != null) {
            return resolved;
          }
        } else {
          _printDebug(
              'Could not match full path $fullPath to matcher ${child.matcher.pattern}.');
        }
      }
    }

    if (tail.isEmpty)
      return null;
    else {
      return _resolve(
          ref, fullPath, method, head + '/' + tail.first, tail.skip(1));
    }
  }

  /// Flattens the route tree into a linear list, in-place.
  void flatten() {
    _root = linearClone().root;
  }

  /// Returns a [Router] with a linear version of this tree.
  Router linearClone({bool normalize: true}) {
    final router = new Router(debug: debug);

    if (normalize) this.normalize();

    _flatten(Route parent, Route route) {
      // if (route.children.isNotEmpty && route.method == '*') return;

      final r = new Route._base();

      r
        .._handlers.addAll(route.handlerSequence)
        .._head = route._head
        .._matcher = route.matcher
        .._method = route.method
        .._name = route.name
        .._parent = route.parent // router.root
        .._path = route.path;

      // New matcher
      final part1 = parent.matcher.pattern
          .replaceAll(_rgxStart, '')
          .replaceAll(_rgxEnd, '')
          .replaceAll(_rgxStraySlashes, '')
          .replaceAll(_straySlashes, '');
      final part2 = route.matcher.pattern
          .replaceAll(_rgxStart, '')
          .replaceAll(_rgxEnd, '')
          .replaceAll(_rgxStraySlashes, '')
          .replaceAll(_straySlashes, '');

      final m = '$part1\\/$part2'.replaceAll(_rgxStraySlashes, '');

      //  r._matcher = new RegExp('^$m\$');
      _printDebug('Matcher of flattened route: ${r.matcher.pattern}');

      router.root._children.add(r);
      route.children.forEach((child) => _flatten(route, child));
    }

    root._children.forEach((child) => _flatten(root, child));
    return router;
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
  void mount(Pattern path, Router router,
      {bool hooked: true, String namespace: null}) {
    // Let's copy middleware, heeding the optional middleware namespace.
    String middlewarePrefix = namespace != null ? "$namespace." : "";

    Map copiedMiddleware = new Map.from(router.requestMiddleware);
    for (String middlewareName in copiedMiddleware.keys) {
      requestMiddleware["$middlewarePrefix$middlewareName"] =
          copiedMiddleware[middlewareName];
    }

    // final route = root.addChild(router.root, join: false);
    final route = root.child(path, debug: debug).addChild(router.root);
    route.debug = debug;

    if (path is! RegExp) {
      // Correct mounted path manually...
      final clean = route.matcher.pattern
          .replaceAll(_rgxStart, '')
          .replaceAll(_rgxEnd, '')
          .replaceAll(_rgxStraySlashes, '');
      route._matcher = new RegExp('^$clean\$');

      final _path = path.toString().replaceAll(_straySlashes, '');

      _migrateRoute(Route r) {
        r._path = '$_path/${r.path}'.replaceAll(_straySlashes, '');
        var m = r.matcher.pattern
            .replaceAll(_rgxStart, '')
            .replaceAll(_rgxEnd, '')
            .replaceAll(_rgxStraySlashes, '')
            .replaceAll(_straySlashes, '');

        final m1 = _matcherify(_path)
            .replaceAll(_rgxStart, '')
            .replaceAll(_rgxEnd, '')
            .replaceAll(_rgxStraySlashes, '')
            .replaceAll(_straySlashes, '');

        m = '$m1/$m'
            .replaceAll(_rgxStraySlashes, '')
            .replaceAll(_straySlashes, '');

        r._matcher = new RegExp('^$m\$');
        _printDebug(
            'New matcher on route in mounted router: ${r.matcher.pattern}');

        if (r._head != null) {
          final head = r._head.pattern
              .replaceAll(_rgxStart, '')
              .replaceAll(_rgxEnd, '')
              .replaceAll(_rgxStraySlashes, '')
              .replaceAll('\\/', '/')
              .replaceAll(_straySlashes, '');
          r._head = new RegExp(_matcherify('$_path/$head')
              .replaceAll(_rgxEnd, '')
              .replaceAll(_rgxStraySlashes, ''));
          _printDebug('Head of migrated route: ${r._head.pattern}');
        }

        r.children.forEach(_migrateRoute);
      }

      route.children.forEach(_migrateRoute);
    }
  }

  /// Removes empty routes that could complicate route resolution.
  void normalize() {
    _printDebug('Normalizing route tree...');

    _normalize(Route route, int index) {
      var merge = route.path.replaceAll(_straySlashes, '').isEmpty &&
          route.children.isNotEmpty;
      merge = merge || route.children.length == 1;

      if (merge) {
        _printDebug('Erasing this route: $route');
        // route.parent._handlers.addAll(route.handlers);

        for (Route child in route.children) {
          route.parent._children.insert(index, child.._parent = route.parent);
          child._handlers.insertAll(0, route.handlers);
        }

        route.parent._children.remove(route);
      }

      for (int i = 0; i < route.children.length; i++) {
        _normalize(route.children[i], i);
      }
    }

    for (int i = 0; i < root.children.length; i++) {
      _normalize(root.children[i], i);
    }
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
  _RootRoute() : super("/", method: '*', name: "<root>");

  @override
  String toString() => "ROOT";
}
