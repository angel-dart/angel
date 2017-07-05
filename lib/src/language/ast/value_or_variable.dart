import 'node.dart';
import 'package:source_span/source_span.dart';
import 'value.dart';
import 'variable.dart';

class ValueOrVariableContext extends Node {
  final ValueContext value;
  final VariableContext variable;

  ValueOrVariableContext(this.value, this.variable) {
    assert(value != null || variable != null);
  }

  @override
  FileSpan get span => value?.span ?? variable.span;

  @override
  String toSource() => '${value?.toSource() ?? variable.toSource()}';
}
