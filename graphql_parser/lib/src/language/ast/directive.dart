import 'package:source_span/source_span.dart';
import '../token.dart';
import 'argument.dart';
import 'input_value.dart';
import 'node.dart';

class DirectiveContext extends Node {
  final Token ARROBA, NAME, COLON, LPAREN, RPAREN;
  final ArgumentContext argument;
  final InputValueContext value;

  DirectiveContext(this.ARROBA, this.NAME, this.COLON, this.LPAREN, this.RPAREN,
      this.argument, this.value) {
    assert(NAME != null);
  }

  /// Use [value] instead.
  @deprecated
  InputValueContext get valueOrVariable => value;

  @override
  FileSpan get span {
    var out = ARROBA.span.expand(NAME.span);

    if (COLON != null) {
      out = out.expand(COLON.span).expand(value.span);
    } else if (LPAREN != null) {
      out = out.expand(LPAREN.span).expand(argument.span).expand(RPAREN.span);
    }

    return out;
  }
}
