library angel_framework.http.route;

/// Represents an endpoint open for connection via the Internet.
class Route {
  /// A regular expression used to match URI's to this route.
  RegExp matcher;
  /// The HTTP method this route responds to.
  String method;
  /// An array of functions, Futures and objects that can respond to this route.
  List handlers = [];
  /// The path this route is mounted on.
  String path;
  /// (Optional) - A name for this route.
  String name;

  Route(String method, Pattern path, [List handlers]) {
    this.method = method;
    if (path is RegExp) {
      this.matcher = path;
      this.path = path.pattern;
    }
    else {
      this.matcher = new RegExp('^' +
          path.toString()
              .replaceAll(new RegExp(r'\/\*$'), "*")
              .replaceAll(new RegExp('\/'), r'\/')
              .replaceAll(new RegExp(':[a-zA-Z_]+'), '([^\/]+)')
              .replaceAll(new RegExp('\\*'), '.*')
          + r'$');
      this.path = path;
    }

    if (handlers != null) {
      this.handlers.addAll(handlers);
    }
  }

  /// Assigns a name to this Route.
  as(String name) {
    this.name = name;
    return this;
  }

  /// Generates a URI to this route with the given parameters.
  String makeUri([Map<String, dynamic> params]) {
    String result = path;
    if (params != null) {
      for (String key in (params.keys)) {
        result = result.replaceAll(new RegExp(":$key" + r"\??"), params[key].toString());
      }
    }

    return result.replaceAll("*", "");
  }

  /// Enables one or more handlers to be called whenever this route is visited.
  Route middleware(handler) {
    if (handler is Iterable)
      handlers.addAll(handler);
    else handlers.add(handler);
    return this;
  }

  /// Extracts route parameters from a given path.
  Map parseParameters(String requestPath) {
    Map result = {};

    Iterable<String> values = _parseParameters(requestPath);
    RegExp rgx = new RegExp(':([a-zA-Z_]+)');
    Iterable<Match> matches = rgx.allMatches(
        path.replaceAll(new RegExp('\/'), r'\/'));
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
    for (int i = 1; i <= routeMatch.groupCount; i++)
      yield routeMatch.group(i);
  }
}
