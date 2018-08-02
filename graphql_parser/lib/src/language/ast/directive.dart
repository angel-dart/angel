import '../token.dart';
import 'argument.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';
import 'value_or_variable.dart';

class DirectiveContext extends Node {
  final Token ARROBA, NAME, COLON, LPAREN, RPAREN;
  final ArgumentContext argument;
  final ValueOrVariableContext valueOrVariable;

  DirectiveContext(this.ARROBA, this.NAME, this.COLON, this.LPAREN, this.RPAREN,
      this.argument, this.valueOrVariable) {
    assert(NAME != null);
  }

  @override
  FileSpan get span {
    var out = ARROBA.span.expand(NAME.span);

    if (COLON != null) {
      out = out.expand(COLON.span).expand(valueOrVariable.span);
    } else if (LPAREN != null) {
      out = out.expand(LPAREN.span).expand(argument.span).expand(RPAREN.span);
    }

    return out;
  }
}
