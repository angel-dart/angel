part of jael.src.text.parselet;

const Map<TokenType, InfixParselet> infixParselets = const {
  TokenType.lParen: const CallParselet(),
  TokenType.elvis_dot: const MemberParselet(),
  TokenType.dot: const MemberParselet(),
  TokenType.lBracket: const IndexerParselet(),
  TokenType.asterisk: const BinaryParselet(14),
  TokenType.slash: const BinaryParselet(14),
  TokenType.percent: const BinaryParselet(14),
  TokenType.plus: const BinaryParselet(13),
  TokenType.minus: const BinaryParselet(13),
  TokenType.lt: const BinaryParselet(11),
  TokenType.lte: const BinaryParselet(11),
  TokenType.gt: const BinaryParselet(11),
  TokenType.gte: const BinaryParselet(11),
  TokenType.equ: const BinaryParselet(10),
  TokenType.nequ: const BinaryParselet(10),
  TokenType.question: const ConditionalParselet(),
  TokenType.equals: const BinaryParselet(3),
};

class ConditionalParselet implements InfixParselet {
  @override
  int get precedence => 4;

  const ConditionalParselet();

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var ifTrue = parser.parseExpression(0);

    if (ifTrue == null) {
      parser.errors.add(new JaelError(JaelErrorSeverity.error,
          'Missing expression in conditional expression.', token.span));
      return null;
    }

    if (!parser.next(TokenType.colon)) {
      parser.errors.add(new JaelError(JaelErrorSeverity.error,
          'Missing ":" in conditional expression.', ifTrue.span));
      return null;
    }

    var colon = parser.current;
    var ifFalse = parser.parseExpression(0);

    if (ifFalse == null) {
      parser.errors.add(new JaelError(JaelErrorSeverity.error,
          'Missing expression in conditional expression.', colon.span));
      return null;
    }

    return new Conditional(left, token, ifTrue, colon, ifFalse);
  }
}

class BinaryParselet implements InfixParselet {
  final int precedence;

  const BinaryParselet(this.precedence);

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var right = parser.parseExpression(precedence);

    if (right == null) {
      if (token.type != TokenType.gt)
        parser.errors.add(new JaelError(
            JaelErrorSeverity.error,
            'Missing expression after operator "${token.span.text}", following expression ${left.span.text}.',
            token.span));
      return null;
    }

    return new BinaryExpression(left, token, right);
  }
}

class CallParselet implements InfixParselet {
  const CallParselet();

  @override
  int get precedence => 19;

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    List<Expression> arguments = [];
    List<NamedArgument> namedArguments = [];
    Expression argument = parser.parseExpression(0);

    while (argument != null) {
      arguments.add(argument);
      if (!parser.next(TokenType.comma)) break;
      parser.skipExtraneous(TokenType.comma);
      argument = parser.parseExpression(0);
    }

    NamedArgument namedArgument = parser.parseNamedArgument();

    while (namedArgument != null) {
      namedArguments.add(namedArgument);
      if (!parser.next(TokenType.comma)) break;
      parser.skipExtraneous(TokenType.comma);
      namedArgument = parser.parseNamedArgument();
    }

    if (!parser.next(TokenType.rParen)) {
      var lastSpan = arguments.isEmpty ? null : arguments.last.span;
      lastSpan ??= token.span;
      parser.errors.add(new JaelError(JaelErrorSeverity.error,
          'Missing ")" after argument list.', lastSpan));
      return null;
    }

    return new Call(left, token, parser.current, arguments, namedArguments);
  }
}

class IndexerParselet implements InfixParselet {
  const IndexerParselet();

  @override
  int get precedence => 19;

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var indexer = parser.parseExpression(0);

    if (indexer == null) {
      parser.errors.add(new JaelError(
          JaelErrorSeverity.error, 'Missing expression after "[".', left.span));
      return null;
    }

    if (!parser.next(TokenType.rBracket)) {
      parser.errors.add(
          new JaelError(JaelErrorSeverity.error, 'Missing "]".', indexer.span));
      return null;
    }

    return new IndexerExpression(left, token, indexer, parser.current);
  }
}

class MemberParselet implements InfixParselet {
  const MemberParselet();

  @override
  int get precedence => 19;

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var name = parser.parseIdentifier();

    if (name == null) {
      parser.errors.add(new JaelError(JaelErrorSeverity.error,
          'Expected the name of a property following "."', token.span));
      return null;
    }

    return new MemberExpression(left, token, name);
  }
}
