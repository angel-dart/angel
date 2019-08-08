import 'package:source_span/source_span.dart';
import '../token.dart';
import 'argument.dart';
import 'input_value.dart';
import 'node.dart';

/// A GraphQL directive, which may or may not have runtime semantics.
class DirectiveContext extends Node {
  /// The source tokens.
  final Token arroba, name, colon, lParen, rParen;
  /// The argument being passed as the directive.
  final ArgumentContext argument;
  /// The (optional) value being passed with the directive.
  final InputValueContext value;

  DirectiveContext(this.arroba, this.name, this.colon, this.lParen, this.rParen,
      this.argument, this.value) {
    assert(name != null);
  }

  /// Use [value] instead.
  @deprecated
  InputValueContext get valueOrVariable => value;

  @deprecated
  Token get ARROBA => arroba;

  @deprecated
  Token get NAME => name;

  @deprecated
  Token get COLON => colon;

  @deprecated
  Token get LPAREN => lParen;

  @deprecated
  Token get RPAREN => rParen;

  @override
  FileSpan get span {
    var out = arroba.span.expand(name.span);

    if (colon != null) {
      out = out.expand(colon.span).expand(value.span);
    } else if (lParen != null) {
      out = out.expand(lParen.span).expand(argument.span).expand(rParen.span);
    }

    return out;
  }
}
