part of angel_framework.http;

class Route {
  RegExp matcher;
  String method;
  List handlers = [];
  String path;
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

  parseParameters(String requestPath) {
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
