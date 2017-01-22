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
  SourceSpan get span {
    SourceLocation end = NAME.span?.end;

    if (valueOrVariable != null)
      end = valueOrVariable.end;
    else if (RPAREN != null) end = RPAREN.span?.end;

    return new SourceSpan(ARROBA.span?.start, end, toSource());
  }

  @override
  String toSource() {
    if (valueOrVariable != null)
      return '@${NAME.text}:${valueOrVariable.toSource()}';
    else if (argument != null)
      return '@${NAME.text}(${argument.toSource()})';
    else
      return '@${NAME.text}';
  }
}
