part of angel_route.src.router;

String _matcherify(String path, {bool expand: true}) {
  var p = path.replaceAll(new RegExp(r'/\*$'), "*").replaceAll('/', r'\/');

  if (expand) {
    var match = _param.firstMatch(p);

    while (match != null) {
      if (match.group(3) == null)
        p = p.replaceAll(match[0], '([^\/]+)');
      else
        p = p.replaceAll(match[0], '(${match[3]})');
      match = _param.firstMatch(p);
    }
  }

  p = p.replaceAll(new RegExp('\\*'), '.*');

  p = '^$p\$';
  return p;
}

String _pathify(String path) {
  var p = path.replaceAll(_straySlashes, '');

  Map<String, String> replace = {};

  for (Match match in _param.allMatches(p)) {
    if (match[3] != null) replace[match[0]] = ':${match[1]}';
  }

  replace.forEach((k, v) {
    p = p.replaceAll(k, v);
  });

  return p;
}

/// Represents a virtual location within an application.
class Route {
  final List<Route> _children = [];
  final List _handlers = [];
  RegExp _head;
  RegExp _matcher;
  String _method;
  String _name;
  Route _parent;
  RegExp _parentResolver;
  String _path;
  String _pathified;
  RegExp _resolver;
  RegExp _stub;

  /// Set to `true` to print verbose debug output when interacting with this route.
  bool debug;

  /// Contains any child routes attached to this one.
  List<Route> get children => new List.unmodifiable(_children);

  /// A `List` of arbitrary objects chosen to respond to this request.
  List get handlers => new List.unmodifiable(_handlers);

  /// A `RegExp` that matches requests to this route.
  RegExp get matcher => _matcher;

  /// The HTTP method this route is designated for.
  String get method => _method;

  /// The name of this route, if any.
  String get name => _name;

  /// The hierarchical parent of this route.
  Route get parent => _parent;

  /// The virtual path on which this route is mounted.
  String get path => _path;

  /// Arbitrary state attached to this route.
  final Extensible state = new Extensible();

  /// The [Route] at the top of the hierarchy this route is found in.
  Route get absoluteParent {
    Route result = this;

    while (result.parent != null) result = result.parent;

    return result;
  }

  /// Returns the [Route] instances that will respond to requests
  /// to the index of this instance's path.
  ///
  /// May return `this`.
  Iterable<Route> get allIndices {
    return children.where((r) => r.path.replaceAll(path, '').isEmpty);
  }

  /// Backtracks up the hierarchy, and builds
  /// a sequential list of all handlers from both
  /// this route, and every found parent route.
  ///
  /// The resulting list puts handlers from routes
  /// higher in the tree at lower indices. Thus,
  /// this can be used in a routing-enabled application
  /// to evaluate multiple middleware on a single route,
  /// and apply them to all children.
  List get handlerSequence {
    final result = [];
    var r = this;

    while (r != null) {
      result.insertAll(0, r.handlers);
      r = r.parent;
    }

    return result;
  }

  /// Returns the [Route] instance that will respond to requests
  /// to the index of this instance's path.
  ///
  /// May return `this`.
  Route get indexRoute {
    return children.firstWhere((r) => r.path.replaceAll(path, '').isEmpty,
        orElse: () => this);
  }

  void _printDebug(msg) {
    if (debug == true) print(msg);
  }

  Route._base();

  Route(Pattern path,
      {Iterable<Route> children: const [],
      this.debug: false,
      Iterable handlers: const [],
      method: "GET",
      String name: null}) {
    if (children != null) _children.addAll(children);
    if (handlers != null) _handlers.addAll(handlers);
    _method = method;
    _name = name;

    if (path is RegExp) {
      _matcher = path;
      _path = path.pattern;
    } else {
      _matcher = new RegExp(
          _matcherify(path.toString().replaceAll(_straySlashes, '')));
      _path = _pathified = _pathify(path.toString());
      _resolver = new RegExp(_matcherify(
          path.toString().replaceAll(_straySlashes, ''),
          expand: false));
    }

    _parentResolver = new RegExp(_matcher.pattern.replaceAll(_rgxEnd, ''));
  }

  /// Splits a route path into a list of segments, and then
  /// builds a hierarchy of off that.
  ///
  /// This should generally be used instead of the original
  /// Route constructor.
  ///
  /// All children and handlers, as well as the method, will be
  /// assigned to the last child route created.
  ///
  /// The final child route is returned.
  factory Route.build(Pattern path,
      {Iterable<Route> children: const [],
      bool debug: false,
      Iterable handlers: const [],
      method: "GET",
      String name: null}) {
    Route result;

    if (path is RegExp) {
      result = new Route(path,
          debug: debug, handlers: handlers, method: method, name: name);
    } else {
      final segments = path
          .toString()
          .split('/')
          .where((str) => str.isNotEmpty)
          .toList(growable: false);

      if (segments.isEmpty) {
        return new Route('/',
            children: children,
            debug: debug,
            handlers: handlers,
            method: method,
            name: name);
      }

      var head = '';

      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];
        head = (head + '/$segment').replaceAll(_straySlashes, '');

        if (i == segments.length - 1) {
          if (result == null) {
            result = new Route(segment, debug: debug);
          } else {
            result = result.child(segment, debug: debug);
          }
        } else {
          if (result == null) {
            result = new Route(segment, debug: debug, method: "*");
          } else {
            result = result.child(segment, debug: debug, method: "*");
          }
        }

        result._head = new RegExp(_matcherify(head).replaceAll(_rgxEnd, ''));
      }
    }

    result._children.addAll(children);
    result._handlers.addAll(handlers);
    result._method = method;
    result._name = name;

    return result..debug = debug;
  }

  /// Combines the paths and matchers of two [Route] instances, and creates a new instance.
  factory Route.join(Route parent, Route child, {bool debug: false}) {
    final String path1 = parent.path
        .replaceAll(_rgxStart, '')
        .replaceAll(_rgxEnd, '')
        .replaceAll(_straySlashes, '');
    final String path2 = child.path
        .replaceAll(_rgxStart, '')
        .replaceAll(_rgxEnd, '')
        .replaceAll(_straySlashes, '');
    final String pattern1 = parent.matcher.pattern
        .replaceAll(_rgxEnd, '')
        .replaceAll(_rgxStraySlashes, '');
    final String pattern2 = child.matcher.pattern
        .replaceAll(_rgxStart, '')
        .replaceAll(_rgxStraySlashes, '');

    final route = new Route('$path1/$path2',
        children: child.children,
        handlers: child.handlers,
        method: child.method,
        name: child.name);

    String separator = (pattern1.isEmpty || pattern1 == '^') ? '' : '\\/';

    parent._children.add(route
      .._matcher = new RegExp('$pattern1$separator$pattern2')
      .._head = new RegExp(
          _matcherify('$path1/$path2'.replaceAll(_straySlashes, ''))
              .replaceAll(_rgxEnd, ''))
      .._parent = parent
      .._stub = child.matcher);

    /*parent._printDebug(
        "Joined '/$path1' and '/$path2', created head: ${route._head.pattern} and stub: ${route._stub.pattern}");*/

    return route..debug = parent.debug || child.debug || debug;
  }

  /// Calls [addChild] on all given routes.
  List<Route> addAll(Iterable<Route> routes, {bool join: true}) {
    return routes.map((route) => addChild(route, join: join)).toList();
  }

  /// Adds the given route as a hierarchical child of this one.
  Route addChild(Route route, {bool join: true}) {
    Route created;

    if (join) {
      created = new Route.join(this, route);
    } else {
      _children.add(created = route.._parent = this);
    }

    return created..debug = debug;
  }

  /// Assigns a name to this route.
  Route as(String name) => this.._name = name;

  /// Creates a hierarchical child of this route with the given path.
  Route child(Pattern path,
      {Iterable<Route> children: const [],
      bool debug: false,
      Iterable handlers: const [],
      String method: "GET",
      String name: null}) {
    final route = new Route.build(path,
        children: children,
        debug: debug,
        handlers: handlers,
        method: method,
        name: name);
    return addChild(route);
  }

  Route clone() {
    final Route route = new Route('');

    return route
      .._children.addAll(children)
      .._handlers.addAll(handlers)
      .._head = _head
      .._matcher = _matcher
      .._method = _method
      .._name = name
      .._parent = _parent
      .._parentResolver = _parentResolver
      .._pathified = _pathified
      .._resolver = _resolver
      .._stub = _stub
      ..state.properties.addAll(state.properties);
  }

  /// Generates a URI to this route with the given parameters.
  String makeUri([Map<String, dynamic> params]) {
    String result = _pathify(path);
    if (params != null) {
      for (String key in (params.keys)) {
        result = result.replaceAll(
            new RegExp(":$key" + r"\??"), params[key].toString());
      }
    }

    return result.replaceAll("*", "");
  }

  /// Attempts to match a path against this route.
  Match match(String path) =>
      matcher.firstMatch(path.replaceAll(_straySlashes, ''));

  /// Extracts route parameters from a given path.
  Map parseParameters(String requestPath) {
    Map result = {};

    Iterable<String> values =
    _parseParameters(requestPath.replaceAll(_straySlashes, ''));

    _printDebug(
        'Searched request path $requestPath and found these values: $values');

    final pathString = _pathify(path).replaceAll(new RegExp('\/'), r'\/');
    Iterable<Match> matches = _param.allMatches(pathString);
    _printDebug(
        'All param names parsed in "$pathString": ${matches.map((m) => m.group(0))}');

    for (int i = 0; i < matches.length && i < values.length; i++) {
      Match match = matches.elementAt(i);
      String paramName = match.group(1);
      String value = values.elementAt(i);
      num numValue = num.parse(value, (_) => double.NAN);
      if (!numValue.isNaN)
        result[paramName] = numValue;
      else
        result[paramName] = value;
    }

    return result;
  }

  _parseParameters(String requestPath) sync* {
    Match routeMatch = matcher.firstMatch(requestPath);

    if (routeMatch != null)
      for (int i = 1; i <= routeMatch.groupCount; i++)
        yield routeMatch.group(i);
  }

  /// Finds the first route available within this hierarchy that can respond to the given path.
  ///
  /// Can be used to navigate a route hierarchy like a file system.
  Route resolve(String path, {bool filter(Route route), String fullPath}) {
    _printDebug(
        'Path to resolve: "/${path.replaceAll(_straySlashes, '')}", our matcher: ${matcher.pattern}');
    bool _filter(route) {
      if (filter == null) {
        _printDebug('No filter provided, returning true for $route');
        return true;
      } else {
        _printDebug('Running filter on $route');
        final result = filter(route);
        _printDebug('Filter result: $result');
        return result;
      }
    }

    final _fullPath = fullPath ?? path;

    if ((path.isEmpty || path == '.') && _filter(indexRoute)) {
      // Try to find index
      _printDebug('Empty path, resolving with indexRoute: $indexRoute');
      return indexRoute;
    } else if (path == '/') {
      return absoluteParent.resolve('');
    } else if (path.replaceAll(_straySlashes, '').isEmpty) {
      for (Route route in children) {
        final stub = route.path.replaceAll(this.path, '');

        if ((stub == '/' || stub.isEmpty) && _filter(route))
          return route.resolve('');
      }

      if (_filter(indexRoute)) {
        _printDebug(
            'Path "/$path" is technically empty, sending to indexRoute: $indexRoute');
        return indexRoute;
      } else
        return null;
    } else if (path == '..') {
      if (parent != null)
        return parent;
      else
        throw new RoutingException.orphan();
    } else if (path.startsWith('/') &&
        path.length > 1 &&
        path[1] != '/' &&
        absoluteParent != null) {
      return absoluteParent.resolve(path.substring(1),
          filter: _filter, fullPath: _fullPath);
    } else if (matcher.hasMatch(path.replaceAll(_straySlashes, '')) ||
        _resolver.hasMatch(path.replaceAll(_straySlashes, ''))) {
      _printDebug(
          'Path "/$path" matched our matcher, sending to indexRoute: $indexRoute');
      return indexRoute;
    } else {
      final segments = path.split('/').where((str) => str.isNotEmpty).toList();
      _printDebug('Segments: $segments on "/${this.path}"');

      if (segments.isEmpty) {
        _printDebug('Empty segments, sending to indexRoute: $indexRoute');
        return indexRoute;
      }

      if (segments[0] == '..') {
        if (parent != null)
          return parent.resolve(segments.skip(1).join('/'),
              filter: _filter, fullPath: _fullPath);
        else
          throw new RoutingException.orphan();
      } else if (segments[0] == '.') {
        return resolve(segments.skip(1).join('/'),
            filter: _filter, fullPath: _fullPath);
      }

      for (Route route in children) {
        final subPath = '${this.path}/${segments[0]}';
        _printDebug(
            'seg0: ${segments[0]}, stub: ${route._stub?.pattern}, path: $path, route.path: ${route.path}, route.matcher: ${route.matcher.pattern}, this.matcher: ${matcher.pattern}');

        if (route.match(subPath) != null ||
            route._resolver.firstMatch(subPath) != null) {
          if (segments.length == 1 && _filter(route))
            return route.resolve('');
          else {
            return route.resolve(segments.skip(1).join('/'),
                filter: _filter,
                fullPath: this.path.replaceAll(_straySlashes, '') +
                    '/' +
                    _fullPath.replaceAll(_straySlashes, ''));
          }
        } else if (route._stub != null && route._stub.hasMatch(segments[0])) {
          if (segments.length == 1) {
            _printDebug('Stub perhaps matches');
            return route.resolve('');
          } else {
            _printDebug(
                'Maybe stub matches. Sending remaining segments to $route');
            return route.resolve(segments.skip(1).join('/'));
          }
        }
      }

      // Try to match "subdirectory"
      for (Route route in children) {
        _printDebug(
            'Trying to match subdir for $path; child ${route.path} on ${this.path}');
        final match = route._parentResolver.firstMatch(path);

        if (match != null) {
          final subPath =
          path.replaceFirst(match[0], '').replaceAll(_straySlashes, '');
          _printDebug("Subdir path: $subPath");

          for (Route child in route.children) {
            final testPath = child.path
                .replaceFirst(route.path, '')
                .replaceAll(_straySlashes, '');

            if (subPath == testPath &&
                (child.match(_fullPath) != null ||
                    child._resolver.firstMatch(_fullPath) != null) &&
                _filter(child)) {
              return child.resolve('');
            }
          }
        }
      }

      // Try to match the whole route, if nothing else works
      for (Route route in children) {
        _printDebug(
            'Trying to match full $_fullPath for ${route.path} on ${this.path}');
        if ((route.match(_fullPath) != null ||
            route._resolver.firstMatch(_fullPath) != null) &&
            _filter(route)) {
          _printDebug('Matched full path!');
          return route.resolve('');
        } else if ((route.match('/$_fullPath') != null ||
            route._resolver.firstMatch('/$_fullPath') != null) &&
            _filter(route)) {
          _printDebug('Matched full path (with a leading slash!)');
          return route.resolve('');
        }
      }

      // Lastly, check to see if we have an index route to resolve with
      if (indexRoute != this) {
        _printDebug('Forwarding "/$path" to indexRoute');
        return indexRoute.resolve(path);
      }

      return null;
    }
  }

  @override
  String toString() => "$method '$path' => ${handlers.length} handler(s)";
}