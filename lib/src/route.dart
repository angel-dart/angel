part of angel_route.src.router;

/// Represents a virtual location within an application.
class Route<T> {
  final String method;
  final String path;
  final List<T> handlers;
  final Map<String, Map<String, dynamic>> _cache = {};
  final RouteDefinition _routeDefinition;
  String name;
  Parser<Map<String, dynamic>> _parser;

  Route(this.path, {@required this.method, @required this.handlers})
      : _routeDefinition = RouteGrammar.routeDefinition
            .parse(new SpanScanner(path.replaceAll(_straySlashes, '')))
            .value {
    if (_routeDefinition?.segments?.isNotEmpty != true)
      _parser =
          match<Map<String, dynamic>>('').value((r) => <String, dynamic>{});
  }

  factory Route.join(Route<T> a, Route<T> b) {
    var start = a.path.replaceAll(_straySlashes, '');
    var end = b.path.replaceAll(_straySlashes, '');
    return new Route('$start/$end'.replaceAll(_straySlashes, ''),
        method: b.method, handlers: b.handlers);
  }

  Parser<Map<String, dynamic>> get parser =>
      _parser ??= _routeDefinition.compile();

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
