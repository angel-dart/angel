import '../token.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';
import 'value_or_variable.dart';

class ArgumentContext extends Node {
  final Token NAME, COLON;
  final ValueOrVariableContext valueOrVariable;

  ArgumentContext(this.NAME, this.COLON, this.valueOrVariable);

  String get name => NAME.text;

  @override
  SourceSpan get span =>
      NAME.span.union(COLON.span).union(valueOrVariable.span);

  @override
  String toSource() => '${NAME.text}:${valueOrVariable.toSource()}';
}
