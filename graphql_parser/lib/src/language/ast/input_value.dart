import 'package:source_span/source_span.dart';
import 'constant.dart';
import 'node.dart';
import 'variable.dart';

class InputValueContext extends Node {
  final ConstantContext constant;
  final VariableContext variable;

  InputValueContext(this.constant, this.variable) {
    assert(constant != null || variable != null);
  }

  @override
  FileSpan get span => constant?.span ?? variable.span;

  Object computeValue(Map<String, dynamic> variables) =>
      constant?.computeValue(variables) ?? variable?.computeValue(variables);
}
