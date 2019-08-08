import '../token.dart';
import 'node.dart';
import 'default_value.dart';
import 'package:source_span/source_span.dart';
import 'type.dart';
import 'variable.dart';

/// A single variable definition.
class VariableDefinitionContext extends Node {
  /// The source token.
  final Token colonToken;

  /// The declared variable.
  final VariableContext variable;

  /// The type of the variable.
  final TypeContext type;

  /// The default value of the variable.
  final DefaultValueContext defaultValue;

  VariableDefinitionContext(this.variable, this.colonToken, this.type,
      [this.defaultValue]);

  /// Use [colonToken] instead.
  @deprecated
  Token get COLON => colonToken;

  @override
  FileSpan get span => variable.span.expand(defaultValue?.span ?? type.span);
}
