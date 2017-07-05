import '../token.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';

class VariableContext extends Node {
  final Token DOLLAR, NAME;

  VariableContext(this.DOLLAR, this.NAME);

  String get name => NAME.text;

  @override
  FileSpan get span => DOLLAR.span.expand(NAME.span);
  // new FileSpan(DOLLAR?.span?.start, NAME?.span?.end, toSource());

  @override
  String toSource() => '\$${NAME.text}';
}
