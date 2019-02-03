part of angel_route.src.router;

/// Represents a virtual location within an application.
class Route<T> {
  final String method;
  final String path;
  final List<T> handlers;
  final Map<String, Map<String, dynamic>> _cache = {};
  final RouteDefinition _routeDefinition;
  String name;
  Parser<RouteResult> _parser;

  Route(this.path, {@required this.method, @required this.handlers})
      : _routeDefinition = RouteGrammar.routeDefinition
            .parse(new SpanScanner(path.replaceAll(_straySlashes, '')))
            .value {
    if (_routeDefinition?.segments?.isNotEmpty != true)
      _parser = match('').map((r) => RouteResult({}));
  }

  factory Route.join(Route<T> a, Route<T> b) {
    var start = a.path.replaceAll(_straySlashes, '');
    var end = b.path.replaceAll(_straySlashes, '');
    return new Route('$start/$end'.replaceAll(_straySlashes, ''),
        method: b.method, handlers: b.handlers);
  }

  Parser<RouteResult> get parser => _parser ??= _routeDefinition.compile();

  @override
  String toString() {
    return '$method $path => $handlers';
  }

  Route<T> clone() {
    return new Route<T>(path, method: method, handlers: handlers)
      .._cache.addAll(_cache);
  }

  String makeUri(Map<String, dynamic> params) {
    var b = new StringBuffer();
    int i = 0;

    for (var seg in _routeDefinition.segments) {
      if (i++ > 0) b.write('/');
      if (seg is ConstantSegment)
        b.write(seg.text);
      else if (seg is ParameterSegment) {
        if (!params.containsKey(seg.name))
          throw new ArgumentError('Missing parameter "${seg.name}".');
        b.write(params[seg.name]);
      }
    }

    return b.toString();
  }
}

/// The result of matching an individual route.
class RouteResult {
  /// The parsed route parameters.
  final Map<String, dynamic> params;

  /// Optional. An explicit "tail" value to set.
  String get tail => _tail;

  String _tail;

  RouteResult(this.params, {String tail}) : _tail = tail;

  void _setTail(String v) => _tail ??= v;

  /// Adds parameters.
  void addAll(Map<String, dynamic> map) {
    params.addAll(map);
  }
}
