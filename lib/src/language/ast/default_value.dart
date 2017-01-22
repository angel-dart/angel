import '../token.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';
import 'value.dart';

class DefaultValueContext extends Node {
  final Token EQUALS;
  final ValueContext value;

  DefaultValueContext(this.EQUALS, this.value);

  @override
  SourceSpan get span =>
      new SourceSpan(EQUALS.span?.start, value.end, toSource());

  @override
  String toSource() => '=${value.toSource()}';
}
