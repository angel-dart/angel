import 'package:source_span/source_span.dart';
import '../token.dart';
import 'argument.dart';
import 'input_value.dart';
import 'node.dart';

/// A GraphQL directive, which may or may not have runtime semantics.
class DirectiveContext extends Node {
  /// The source tokens.
  final Token arrobaToken, nameToken, colonToken, lParenToken, rParenToken;

  /// The argument being passed as the directive.
  final ArgumentContext argument;

  /// The (optional) value being passed with the directive.
  final InputValueContext value;

  DirectiveContext(this.arrobaToken, this.nameToken, this.colonToken,
      this.lParenToken, this.rParenToken, this.argument, this.value) {
    assert(nameToken != null);
  }

  /// Use [value] instead.
  @deprecated
  InputValueContext get valueOrVariable => value;

  @deprecated
  Token get ARROBA => arrobaToken;

  @deprecated
  Token get NAME => nameToken;

  @deprecated
  Token get COLON => colonToken;

  @deprecated
  Token get LPAREN => lParenToken;

  @deprecated
  Token get RPAREN => rParenToken;

  @override
  FileSpan get span {
    var out = arrobaToken.span.expand(nameToken.span);

    if (colonToken != null) {
      out = out.expand(colonToken.span).expand(value.span);
    } else if (lParenToken != null) {
      out = out
          .expand(lParenToken.span)
          .expand(argument.span)
          .expand(rParenToken.span);
    }

    return out;
  }
}
