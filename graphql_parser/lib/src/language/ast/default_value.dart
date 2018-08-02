import '../token.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';
import 'value.dart';

class DefaultValueContext extends Node {
  final Token EQUALS;
  final ValueContext value;

  DefaultValueContext(this.EQUALS, this.value);

  @override
  FileSpan get span => EQUALS.span.expand(value.span);

  @override
  String toSource() => '=${value.toSource()}';
}
