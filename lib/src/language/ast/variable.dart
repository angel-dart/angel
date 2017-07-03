import '../token.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';

class VariableContext extends Node {
  final Token DOLLAR, NAME;

  VariableContext(this.DOLLAR, this.NAME);

  String get name => NAME.text;

  @override
  SourceSpan get span =>
      new SourceSpan(DOLLAR?.span?.start, NAME?.span?.end, toSource());

  @override
  String toSource() => '\$${NAME.text}';
}
