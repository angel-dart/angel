part of jael.src.text.parselet;

const Map<TokenType, InfixParselet> infixParselets = {
  TokenType.lParen: CallParselet(),
  TokenType.elvis_dot: MemberParselet(),
  TokenType.dot: MemberParselet(),
  TokenType.lBracket: IndexerParselet(),
  TokenType.asterisk: BinaryParselet(14),
  TokenType.slash: BinaryParselet(14),
  TokenType.percent: BinaryParselet(14),
  TokenType.plus: BinaryParselet(13),
  TokenType.minus: BinaryParselet(13),
  TokenType.lt: BinaryParselet(11),
  TokenType.lte: BinaryParselet(11),
  TokenType.gt: BinaryParselet(11),
  TokenType.gte: BinaryParselet(11),
  TokenType.equ: BinaryParselet(10),
  TokenType.nequ: BinaryParselet(10),
  TokenType.question: ConditionalParselet(),
  TokenType.equals: BinaryParselet(3),
  TokenType.elvis: BinaryParselet(3),
};

class ConditionalParselet implements InfixParselet {
  @override
  int get precedence => 4;

  const ConditionalParselet();

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var ifTrue = parser.parseExpression(0);

    if (ifTrue == null) {
      parser.errors.add(JaelError(JaelErrorSeverity.error,
          'Missing expression in conditional expression.', token.span));
      return null;
    }

    if (!parser.next(TokenType.colon)) {
      parser.errors.add(JaelError(JaelErrorSeverity.error,
          'Missing ":" in conditional expression.', ifTrue.span));
      return null;
    }

    var colon = parser.current;
    var ifFalse = parser.parseExpression(0);

    if (ifFalse == null) {
      parser.errors.add(JaelError(JaelErrorSeverity.error,
          'Missing expression in conditional expression.', colon.span));
      return null;
    }

    return Conditional(left, token, ifTrue, colon, ifFalse);
  }
}

class BinaryParselet implements InfixParselet {
  final int precedence;

  const BinaryParselet(this.precedence);

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var right = parser.parseExpression(precedence);

    if (right == null) {
      if (token.type != TokenType.gt) {
        parser.errors.add(JaelError(
            JaelErrorSeverity.error,
            'Missing expression after operator "${token.span.text}", following expression ${left.span.text}.',
            token.span));
      }
      return null;
    }

    return BinaryExpression(left, token, right);
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
      parser.errors.add(JaelError(JaelErrorSeverity.error,
          'Missing ")" after argument list.', lastSpan));
      return null;
    }

    return Call(left, token, parser.current, arguments, namedArguments);
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
      parser.errors.add(JaelError(
          JaelErrorSeverity.error, 'Missing expression after "[".', left.span));
      return null;
    }

    if (!parser.next(TokenType.rBracket)) {
      parser.errors.add(
          JaelError(JaelErrorSeverity.error, 'Missing "]".', indexer.span));
      return null;
    }

    return IndexerExpression(left, token, indexer, parser.current);
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
      parser.errors.add(JaelError(JaelErrorSeverity.error,
          'Expected the name of a property following "."', token.span));
      return null;
    }

    return MemberExpression(left, token, name);
  }
}
