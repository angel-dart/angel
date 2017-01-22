import '../token.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';
import 'value_or_variable.dart';

class ArgumentContext extends Node {
  final Token NAME, COLON;
  final ValueOrVariableContext valueOrVariable;

  ArgumentContext(this.NAME, this.COLON, this.valueOrVariable);

  @override
  SourceSpan get span =>
      new SourceSpan(NAME.span?.start, valueOrVariable.end, toSource());

  @override
  String toSource() => '${NAME.text}:${valueOrVariable.toSource()}';
}
