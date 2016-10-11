final RegExp _rgxEnd = new RegExp(r'\$');
final RegExp _rgxStart = new RegExp(r'\^');
final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

class Route {
  final List<Route> _children = [];
  final List _handlers = [];
  RegExp _matcher;
  Route _parent;
  String _path;
  List<Route> get children => new List.unmodifiable(_children);
  List get handlers => new List.unmodifiable(_handlers);
  RegExp get matcher => _matcher;
  final String method;
  final String name;
  Route get parent => _parent;
  String get path => _path;

  Route(Pattern path,
      {Iterable<Route> children: const [],
      Iterable handlers: const [],
      this.method: "GET",
      this.name: null}) {
    if (children != null) _children.addAll(children);
    if (handlers != null) _handlers.addAll(handlers);

    if (path is RegExp) {
      _matcher = path;
      _path = path.pattern;
    } else {
      _matcher = new RegExp(_path = path
          .toString()
          .replaceAll(_straySlashes, '')
          .replaceAll(new RegExp(r'\/\*$'), "*")
          .replaceAll(new RegExp('\/'), r'\/')
          .replaceAll(new RegExp(':[a-zA-Z_]+'), '([^\/]+)')
          .replaceAll(new RegExp('\\*'), '.*'));
    }
  }

  factory Route.join(Route parent, Route child) {
    final String path1 = parent.path.replaceAll(_straySlashes, '');
    final String path2 = child.path.replaceAll(_straySlashes, '');
    final String pattern1 = parent.matcher.pattern.replaceAll(_rgxEnd, '');
    final String pattern2 = child.matcher.pattern.replaceAll(_rgxStart, '');

    final route = new Route(new RegExp('$pattern1/$pattern2'),
        children: child.children,
        handlers: child.handlers,
        method: child.method,
        name: child.name);

    return route
      ..parent = parent
      .._path = '$path1/$path2';
  }

  Route addChild(Route route, {bool join: true}) {
    Route created = join ? new Route.join(this, route) : route;
    _children.add(created);
    return created;
  }

  Route child(Pattern path,
      {Iterable<Route> children: const [],
      Iterable handlers: const [],
      String method: "GET",
      String name: null}) {
    final route = new Route(path,
        children: children, handlers: handlers, method: method, name: name);
    return addChild(route);
  }

  Match match(String path) => matcher.firstMatch(path);

  Route resolve(String path) {
    if (path.isEmpty ||
        path == '.' ||
        path.replaceAll(_straySlashes, '').isEmpty) {
      return this;
    } else {
      final segments = path.split('/');

      for (Route route in children) {
        final subPath = '${this.path}/${segments[0]}';

        if (route.match(subPath) != null) {
          if (segments.length == 1)
            return route;
          else {
            return route.resolve(segments.skip(1).join('/'));
          }
        }
      }

      return null;
    }
  }
}
