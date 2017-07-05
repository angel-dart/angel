import 'package:source_span/source_span.dart';
import '../token.dart';
import 'node.dart';
import 'value_or_variable.dart';

class ArgumentContext extends Node {
  final Token NAME, COLON;
  final ValueOrVariableContext valueOrVariable;

  ArgumentContext(this.NAME, this.COLON, this.valueOrVariable);

  String get name => NAME.text;

  @override
  FileSpan get span =>
      NAME.span.expand(COLON.span).expand(valueOrVariable.span);

  @override
  String toSource() => '${NAME.text}:${valueOrVariable.toSource()}';
}
