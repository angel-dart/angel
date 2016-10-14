import 'extensible.dart';
import 'routing_exception.dart';

final RegExp _param = new RegExp(r':([A-Za-z0-9_]+)(\((.+)\))?');
final RegExp _rgxEnd = new RegExp(r'\$+$');
final RegExp _rgxStart = new RegExp(r'^\^+');
final RegExp _rgxStraySlashes = new RegExp(r'(^((\\/)|(/))+)|(((\\/)|(/))+$)');
final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

String _matcherify(String path, {bool expand: true}) {
  var p = path.replaceAll(new RegExp(r'\/\*$'), "*").replaceAll('/', r'\/');

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

class Route {
  final List<Route> _children = [];
  final List _handlers = [];
  RegExp _matcher;
  String _method;
  String _name;
  Route _parent;
  String _path;
  String _pathified;
  RegExp _resolver;
  List<Route> get children => new List.unmodifiable(_children);
  List get handlers => new List.unmodifiable(_handlers);
  RegExp get matcher => _matcher;
  String get method => _method;
  String get name => _name;
  Route get parent => _parent;
  String get path => _path;
  final Extensible state = new Extensible();

  Route get absoluteParent {
    Route result = this;

    while (result.parent != null) result = result.parent;

    return result;
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

  Route(Pattern path,
      {Iterable<Route> children: const [],
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
      Iterable handlers: const [],
      method: "GET",
      String name: null}) {
    final segments = path.toString().split('/').where((str) => str.isNotEmpty);
    print('Seg: $segments');
    Route result;

    for (String segment in segments) {
      print('SEGGG: $segment');
      if (result == null)
        result = new Route(segment);
      else
        result = result.child(segment);
    }

    print('result: ${result.path}');

    result._children.addAll(children);
    result._handlers.addAll(handlers);
    result._method = method;
    result._name = name;

    return result;
  }

  factory Route.join(Route parent, Route child) {
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
      .._parent = parent);

    return route;
  }

  List<Route> addAll(Iterable<Route> routes, {bool join: true}) {
    return routes.map((route) => addChild(route, join: join)).toList();
  }

  Route addChild(Route route, {bool join: true}) {
    Route created = join ? new Route.join(this, route) : route.._parent = this;
    _children.add(created);
    return created;
  }

  /// Assigns a name to this route.
  Route as(String name) => this.._name = name;

  Route child(Pattern path,
      {Iterable<Route> children: const [],
      Iterable handlers: const [],
      String method: "GET",
      String name: null}) {
    final route = new Route.build(path,
        children: children, handlers: handlers, method: method, name: name);
    return addChild(route);
  }

  /// Generates a URI to this route with the given parameters.
  String makeUri([Map<String, dynamic> params]) {
    String result = _pathified;
    if (params != null) {
      for (String key in (params.keys)) {
        result = result.replaceAll(
            new RegExp(":$key" + r"\??"), params[key].toString());
      }
    }

    return result.replaceAll("*", "");
  }

  Match match(String path) =>
      matcher.firstMatch(path.replaceAll(_straySlashes, ''));

  /// Extracts route parameters from a given path.
  Map parseParameters(String requestPath) {
    Map result = {};

    Iterable<String> values =
        _parseParameters(requestPath.replaceAll(_straySlashes, ''));
    Iterable<Match> matches =
        _param.allMatches(_pathified.replaceAll(new RegExp('\/'), r'\/'));
    for (int i = 0; i < matches.length; i++) {
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
    for (int i = 1; i <= routeMatch.groupCount; i++) yield routeMatch.group(i);
  }

  Route resolve(String path, [bool filter(Route route)]) {
    final _filter = filter ?? (_) => true;

    if ((path.isEmpty || path == '.') && _filter(this)) {
      return this;
    } else if (path.replaceAll(_straySlashes, '').isEmpty) {
      for (Route route in children) {
        final stub = route.path.replaceAll(this.path, '');

        if (stub == '/' || stub.isEmpty && _filter(route)) return route;
      }

      if (_filter(this))
        return this;
      else
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
      return absoluteParent.resolve(path.substring(1), _filter);
    } else if (matcher.hasMatch(path.replaceAll(_straySlashes, '')) ||
        _resolver.hasMatch(path.replaceAll(_straySlashes, ''))) {
      return this;
    } else {
      final segments = path.split('/').where((str) => str.isNotEmpty).toList();

      if (segments[0] == '..') {
        if (parent != null)
          return parent.resolve(segments.skip(1).join('/'), _filter);
        else
          throw new RoutingException.orphan();
      } else if (segments[0] == '.') {
        return resolve(segments.skip(1).join('/'), _filter);
      }

      for (Route route in children) {
        final subPath = '${this.path}/${segments[0]}';
        print('Subpath for $path on ${this.path} = $subPath');

        if (route.match(subPath) != null ||
            route._resolver.firstMatch(subPath) != null) {
          if (segments.length == 1 && _filter(route))
            return route;
          else {
            return route.resolve(segments.skip(1).join('/'), _filter);
          }
        }
      }

      // Try to match the whole route, if nothing else works
      for (Route route in children) {
        print(
            'Full path is $path, path is ${route.path}, matcher: ${route.matcher.pattern}, resolver: ${route._resolver.pattern}');
        if ((route.match(path) != null ||
                route._resolver.firstMatch(path) != null) &&
            _filter(route))
          return route;
        else if ((route.match('/$path') != null ||
                route._resolver.firstMatch('/$path') != null) &&
            _filter(route)) return route;
      }

      return null;
    }
  }
}
