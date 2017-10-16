part of jael.src.text.parselet;

const Map<TokenType, PrefixParselet> prefixParselets = const {
  TokenType.exclamation: const NotParselet(),
  TokenType.$new: const NewParselet(),
  TokenType.number: const NumberParselet(),
  TokenType.hex: const HexParselet(),
  TokenType.string: const StringParselet(),
  TokenType.lCurly: const MapParselet(),
  TokenType.lBracket: const ArrayParselet(),
  TokenType.id: const IdentifierParselet(),
  TokenType.lParen: const ParenthesisParselet(),
};

class NotParselet implements PrefixParselet {
  const NotParselet();

  @override
  Expression parse(Parser parser, Token token) {
    var expression = parser.parseExpression(0);

    if (expression == null) {
      parser.errors.add(new JaelError(JaelErrorSeverity.error,
          'Missing expression after "!" in negation expression.', token.span));
    }

    return new Negation(token, expression);
  }
}

class NewParselet implements PrefixParselet {
  const NewParselet();

  @override
  Expression parse(Parser parser, Token token) {
    var call = parser.parseExpression(0);

    if (call == null) {
      parser.errors.add(new JaelError(
          JaelErrorSeverity.error,
          '"new" must precede a call expression. Nothing was found.',
          call.span));
      return null;
    } else if (call is! Call) {
      parser.errors.add(new JaelError(
          JaelErrorSeverity.error,
          '"new" must precede a call expression, not a(n) ${call.runtimeType}.',
          call.span));
      return null;
    } else {
      return new NewExpression(token, call);
    }
  }
}

class NumberParselet implements PrefixParselet {
  const NumberParselet();

  @override
  Expression parse(Parser parser, Token token) => new NumberLiteral(token);
}

class HexParselet implements PrefixParselet {
  const HexParselet();

  @override
  Expression parse(Parser parser, Token token) => new HexLiteral(token);
}

class StringParselet implements PrefixParselet {
  const StringParselet();

  @override
  Expression parse(Parser parser, Token token) =>
      new StringLiteral(token, StringLiteral.parseValue(token));
}

class ArrayParselet implements PrefixParselet {
  const ArrayParselet();

  @override
  Expression parse(Parser parser, Token token) {
    List<Expression> items = [];
    Expression item = parser.parseExpression(0);

    while (item != null) {
      items.add(item);
      if (!parser.next(TokenType.comma)) break;
      parser.skipExtraneous(TokenType.comma);
      item = parser.parseExpression(0);
    }

    if (!parser.next(TokenType.rBracket)) {
      var lastSpan = items.isEmpty ? null : items.last.span;
      lastSpan ??= token.span;
      parser.errors.add(new JaelError(JaelErrorSeverity.error,
          'Missing "]" to terminate array literal.', lastSpan));
      return null;
    }

    return new Array(token, parser.current, items);
  }
}

class MapParselet implements PrefixParselet {
  const MapParselet();

  @override
  Expression parse(Parser parser, Token token) {
    var pairs = <KeyValuePair>[];
    var pair = parser.parseKeyValuePair();

    while (pair != null) {
      pairs.add(pair);
      if (!parser.next(TokenType.comma)) break;
      parser.skipExtraneous(TokenType.comma);
      pair = parser.parseKeyValuePair();
    }

    if (!parser.next(TokenType.rCurly)) {
      var lastSpan = pairs.isEmpty ? token.span : pairs.last.span;
      parser.errors.add(new JaelError(
          JaelErrorSeverity.error, 'Missing "}" in map literal.', lastSpan));
      return null;
    }

    return new MapLiteral(token, pairs, parser.current);
  }
}

class IdentifierParselet implements PrefixParselet {
  const IdentifierParselet();

  @override
  Expression parse(Parser parser, Token token) => new Identifier(token);
}

class ParenthesisParselet implements PrefixParselet {
  const ParenthesisParselet();

  @override
  Expression parse(Parser parser, Token token) {
    var expression = parser.parseExpression(0);

    if (expression == null) {
      parser.errors.add(new JaelError(JaelErrorSeverity.error,
          'Missing expression after "(".', token.span));
      return null;
    }

    if (!parser.next(TokenType.rParen)) {
      parser.errors.add(new JaelError(
          JaelErrorSeverity.error, 'Missing ")".', expression.span));
      return null;
    }

    return expression;
  }
}
