import '../token.dart';
import 'node.dart';
import 'default_value.dart';
import 'package:source_span/src/span.dart';
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
  SourceSpan get span =>
      new SourceSpan(variable.start, defaultValue?.end ?? type.end, toSource());

  @override
  String toSource() =>
      '${variable.toSource()}:${type.toSource()}${defaultValue?.toSource() ?? ""}';
}
