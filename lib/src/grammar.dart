part of angel_route.src.router;

class RouteGrammar {
  static const String notSlashRgx = r'([^/]+)';
  //static final RegExp rgx = new RegExp(r'\((.+)\)');
  static final Parser<String> notSlash =
      match<String>(new RegExp(notSlashRgx)).value((r) => r.span.text);

  static final Parser<Match> regExp =
      match<Match>(new RegExp(r'\(([^\n)]+)\)([^/]+)?'))
          .value((r) => r.scanner.lastMatch);

  static final Parser<Match> parameterName = match<Match>(
          new RegExp('$notSlashRgx?' r':([A-Za-z0-9_]+)' r'([^(/\n])?'))
      .value((r) => r.scanner.lastMatch);

  static final Parser<ParameterSegment> parameterSegment = chain([
    parameterName,
    match<bool>('?').value((r) => true).opt(),
    regExp.opt(),
  ]).map((r) {
    var match = r.value[0] as Match;
    var rgxMatch = r.value[2] as Match;

    var pre = match[1] ?? '';
    var post = match[3] ?? '';
    RegExp rgx;

    if (rgxMatch != null) {
      rgx = RegExp('(${rgxMatch[1]})');
      post = (rgxMatch[2] ?? '') + post;
    }

    if (pre.isNotEmpty || post.isNotEmpty) {
      if (rgx != null) {
        var pattern = pre + rgx.pattern + post;
        rgx = RegExp(pattern);
      } else {
        rgx = RegExp('$pre$notSlashRgx$post');
      }
    }

    var s = new ParameterSegment(match[2], rgx);
    return r.value[1] == true ? new OptionalSegment(s) : s;
  });

  static final Parser<ParsedParameterSegment> parsedParameterSegment = chain([
    match(new RegExp(r'(int|num|double)'),
            errorMessage: 'Expected "int","double", or "num".')
        .map((r) => r.span.text),
    parameterSegment,
  ]).map((r) {
    return new ParsedParameterSegment(
        r.value[0] as String, r.value[1] as ParameterSegment);
  });

  static final Parser<WildcardSegment> wildcardSegment =
      match<WildcardSegment>(RegExp('$notSlashRgx?' r'\*' '$notSlashRgx?'))
          .value((r) {
    var m = r.scanner.lastMatch;
    var pre = m[1] ?? '';
    var post = m[2] ?? '';
    return new WildcardSegment(pre, post);
  });

  static final Parser<ConstantSegment> constantSegment =
      notSlash.map<ConstantSegment>((r) => new ConstantSegment(r.value));

  static final Parser<SlashSegment> slashSegment =
      match(SlashSegment.rgx).map((_) => SlashSegment());

  static final Parser<RouteSegment> routeSegment = any([
    //slashSegment,
    parsedParameterSegment,
    parameterSegment,
    wildcardSegment,
    constantSegment
  ]);

  // static final Parser<RouteDefinition> routeDefinition = routeSegment
  //     .star()
  //     .map<RouteDefinition>((r) => new RouteDefinition(r.value ?? []))
  //     .surroundedBy(match(RegExp(r'/*')).opt());

  static final Parser slashes = match(RegExp(r'/*'));

  static final Parser<RouteDefinition> routeDefinition = routeSegment
      .separatedBy(slashes)
      .map<RouteDefinition>((r) => new RouteDefinition(r.value ?? []))
      .surroundedBy(slashes.opt());
}

class RouteDefinition {
  final List<RouteSegment> segments;

  RouteDefinition(this.segments);

  Parser<RouteResult> compile() {
    Parser<RouteResult> out;

    for (int i = 0; i < segments.length; i++) {
      var s = segments[i];
      bool isLast = i == segments.length - 1;
      if (out == null)
        out = s.compile(isLast);
      else
        out = s.compileNext(
            out.then(match('/')).index(0).cast<RouteResult>(), isLast);
    }

    return out;
  }
}

abstract class RouteSegment {
  Parser<RouteResult> compile(bool isLast);

  Parser<RouteResult> compileNext(Parser<RouteResult> p, bool isLast);
}

class SlashSegment implements RouteSegment {
  static final RegExp rgx = RegExp(r'/+');

  const SlashSegment();

  @override
  Parser<RouteResult> compile(bool isLast) {
    return match(rgx).map((_) => RouteResult({}));
  }

  @override
  Parser<RouteResult> compileNext(Parser<RouteResult> p, bool isLast) {
    return p.then(compile(isLast)).index(0).cast<RouteResult>();
  }

  @override
  String toString() => 'Slash';
}

class ConstantSegment extends RouteSegment {
  final String text;

  ConstantSegment(this.text);

  @override
  String toString() {
    return 'Constant: $text';
  }

  @override
  Parser<RouteResult> compile(bool isLast) {
    return match(text).map((r) => RouteResult({}));
  }

  @override
  Parser<RouteResult> compileNext(Parser<RouteResult> p, bool isLast) {
    return p.then(compile(isLast)).index(0).cast<RouteResult>();
  }
}

class WildcardSegment extends RouteSegment {
  final String pre, post;

  WildcardSegment(this.pre, this.post);

  @override
  String toString() {
    return 'Wildcard segment';
  }

  String _symbol(bool isLast) {
    if (isLast) return r'.*';
    return r'[^/]*';
  }

  RegExp _compile(bool isLast) {
    return RegExp('$pre(${_symbol(isLast)})$post');
    // if (isLast) return match(new RegExp(r'.*'));
    // return match(new RegExp(r'[^/]*'));
  }

  @override
  Parser<RouteResult> compile(bool isLast) {
    return match(_compile(isLast))
        .map((r) => RouteResult({}, tail: r.scanner.lastMatch[1]));
  }

  @override
  Parser<RouteResult> compileNext(Parser<RouteResult> p, bool isLast) {
    return p.then(compile(isLast)).map((r) {
      var items = r.value.cast<RouteResult>();
      var a = items[0], b = items[1];
      return a
        ..addAll(b?.params ?? {})
        .._setTail(b?.tail);
    });
  }
}

class OptionalSegment extends ParameterSegment {
  final ParameterSegment parameter;

  OptionalSegment(this.parameter) : super(parameter.name, parameter.regExp);

  @override
  String toString() {
    return 'Optional: $parameter';
  }

  @override
  Parser<RouteResult> compile(bool isLast) {
    return super.compile(isLast).opt();
  }

  @override
  Parser<RouteResult> compileNext(Parser<RouteResult> p, bool isLast) {
    return p.then(_compile().opt()).map((r) {
      if (r.value[1] == null) return r.value[0] as RouteResult;
      return (r.value[0] as RouteResult)
        ..addAll({name: Uri.decodeComponent(r.value[1] as String)});
    });
  }
}

class ParameterSegment extends RouteSegment {
  final String name;
  final RegExp regExp;

  ParameterSegment(this.name, this.regExp);

  @override
  String toString() {
    if (regExp != null) return 'Param: $name (${regExp.pattern})';
    return 'Param: $name';
  }

  Parser<String> _compile() {
    return regExp != null
        ? match<String>(regExp).value((r) => r.scanner.lastMatch[1])
        : RouteGrammar.notSlash;
  }

  @override
  Parser<RouteResult> compile(bool isLast) {
    return _compile()
        .map((r) => RouteResult({name: Uri.decodeComponent(r.value)}));
  }

  @override
  Parser<RouteResult> compileNext(Parser<RouteResult> p, bool isLast) {
    return p.then(_compile()).map((r) {
      return (r.value[0] as RouteResult)
        ..addAll({name: Uri.decodeComponent(r.value[1] as String)});
    });
  }
}

class ParsedParameterSegment extends RouteSegment {
  final String type;
  final ParameterSegment parameter;

  ParsedParameterSegment(this.type, this.parameter);

  num getValue(String s) {
    switch (type) {
      case 'int':
        return int.parse(s);
      case 'double':
        return double.parse(s);
      default:
        return num.parse(s);
    }
  }

  @override
  Parser<RouteResult> compile(bool isLast) {
    return parameter._compile().map((r) => RouteResult(
        {parameter.name: getValue(Uri.decodeComponent(r.span.text))}));
  }

  @override
  Parser<RouteResult> compileNext(Parser<RouteResult> p, bool isLast) {
    return p.then(parameter._compile()).map((r) {
      return (r.value[0] as RouteResult)
        ..addAll({
          parameter.name: getValue(Uri.decodeComponent(r.value[1] as String))
        });
    });
  }
}
