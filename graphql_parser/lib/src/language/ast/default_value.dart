import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';
import 'node.dart';

class DefaultValueContext extends Node {
  final Token EQUALS;
  final InputValueContext value;

  DefaultValueContext(this.EQUALS, this.value);

  @override
  FileSpan get span => EQUALS.span.expand(value.span);
}
