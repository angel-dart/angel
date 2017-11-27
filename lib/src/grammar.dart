part of angel_route.src.router;

class _RouteGrammar {
  static final Parser<String> notSlash =
      match(new RegExp(r'[^/]+')).value((r) => r.span.text);
  static final Parser<RegExp> regExp = new _RegExpParser();
  static final Parser<String> parameterName =
      match(new RegExp(r':([A-Za-z0-9_]+)'))
          .value((r) => r.span.text.substring(1));

  static final Parser<_ParameterSegment> parameterSegment = chain([
    parameterName,
    match('?').value((r) => true).opt(),
    regExp.opt(),
  ]).map((r) {
    var s = new _ParameterSegment(r.value[0], r.value[2]);
    return r.value[1] == true ? new _OptionalSegment(s) : s;
  });

  static final Parser<_WildcardSegment> wildcardSegment =
      match('*').value((r) => new _WildcardSegment());

  static final Parser<_ConstantSegment> constantSegment =
      notSlash.map((r) => new _ConstantSegment(r.value));

  static final Parser<_RouteSegment> routeSegment =
      any([parameterSegment, wildcardSegment, constantSegment]);

  static final Parser<_RouteDefinition> routeDefinition = routeSegment
      .separatedBy(match('/'))
      .map((r) => new _RouteDefinition(r.value ?? []))
      .surroundedBy(match('/').star().opt());
}

class _RegExpParser extends Parser<RegExp> {
  static final RegExp rgx = new RegExp(r'\((.+)\)');

  @override
  ParseResult<RegExp> parse(SpanScanner scanner, [int depth = 1]) {
    if (!scanner.matches(rgx)) return new ParseResult(this, false, []);
    return new ParseResult(this, true, [],
        span: scanner.lastSpan, value: new RegExp(scanner.lastMatch[1]));
  }
}

class _RouteDefinition {
  final List<_RouteSegment> segments;

  _RouteDefinition(this.segments);

  Parser<Map<String, String>> compile() {
    Parser<Map<String, String>> out;

    for (var s in segments) {
      if (out == null)
        out = s.compile();
      else
        out = s.compileNext(out.then(match('/')).index(0));
    }

    return out;
  }
}

abstract class _RouteSegment {
  Parser<Map<String, String>> compile();
  Parser<Map<String, String>> compileNext(Parser<Map<String, String>> p);
}

class _ConstantSegment extends _RouteSegment {
  final String text;

  _ConstantSegment(this.text);

  @override
  String toString() {
    return 'Constant: $text';
  }

  @override
  Parser<Map<String, String>> compile() {
    return match(text).value((r) => {});
  }

  @override
  Parser<Map<String, String>> compileNext(Parser<Map<String, String>> p) {
    return p.then(compile()).index(0);
  }
}

class _WildcardSegment extends _RouteSegment {
  @override
  String toString() {
    return 'Wildcard segment';
  }

  Parser<Map<String, String>> _compile() {
    return match(new RegExp(r'[^/]*'));
  }

  @override
  Parser<Map<String, String>> compile() {
    return _compile().map((r) => {});
  }

  @override
  Parser<Map<String, String>> compileNext(Parser<Map<String, String>> p) {
    return p.then(_compile()).index(0);
  }
}

class _OptionalSegment extends _ParameterSegment {
  final _ParameterSegment parameter;

  _OptionalSegment(this.parameter) : super(parameter.name, parameter.regExp);

  @override
  String toString() {
    return 'Optional: $parameter';
  }

  @override
  Parser<Map<String, String>> compile() {
    return super.compile().opt();
  }

  @override
  Parser<Map<String, String>> compileNext(Parser<Map<String, String>> p) {
    return p.then(_compile().opt()).map((r) {
      if (r.value[1] == null) return r.value[0];
      return r.value[0]..addAll({name: Uri.decodeComponent(r.value[1])});
    });
  }
}

class _ParameterSegment extends _RouteSegment {
  final String name;
  final RegExp regExp;

  _ParameterSegment(this.name, this.regExp);

  @override
  String toString() {
    if (regExp != null) return 'Param: $name (${regExp.pattern})';
    return 'Param: $name';
  }

  Parser<Map<String, String>> _compile() {
    return regExp != null
        ? match(regExp).value((r) => r.span.text)
        : _RouteGrammar.notSlash;
  }

  @override
  Parser<Map<String, String>> compile() {
    return _compile().map((r) => {name: Uri.decodeComponent(r.span.text)});
  }

  @override
  Parser<Map<String, String>> compileNext(Parser<Map<String, String>> p) {
    return p.then(_compile()).map((r) {
      return r.value[0]..addAll({name: Uri.decodeComponent(r.value[1])});
    });
  }
}
