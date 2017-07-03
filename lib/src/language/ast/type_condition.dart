import 'node.dart';
import 'package:source_span/src/span.dart';
import 'type_name.dart';

class TypeConditionContext extends Node {
  final TypeNameContext typeName;

  TypeConditionContext(this.typeName);

  @override
  SourceSpan get span => typeName.span;

  @override
  String toSource() => typeName.toSource();
}
