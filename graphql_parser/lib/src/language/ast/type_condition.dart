import 'node.dart';
import 'package:source_span/source_span.dart';
import 'type_name.dart';

class TypeConditionContext extends Node {
  final TypeNameContext typeName;

  TypeConditionContext(this.typeName);

  @override
  FileSpan get span => typeName.span;
}
