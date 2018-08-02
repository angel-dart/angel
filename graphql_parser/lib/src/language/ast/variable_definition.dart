import '../token.dart';
import 'node.dart';
import 'default_value.dart';
import 'package:source_span/source_span.dart';
import 'type.dart';
import 'variable.dart';

class VariableDefinitionContext extends Node {
  final Token COLON;
  final VariableContext variable;
  final TypeContext type;
  final DefaultValueContext defaultValue;

  VariableDefinitionContext(this.variable, this.COLON, this.type,
      [this.defaultValue]);

  @override
  FileSpan get span => variable.span.expand(defaultValue?.span ?? type.span);
}
