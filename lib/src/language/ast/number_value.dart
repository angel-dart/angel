import '../token.dart';
import 'package:source_span/src/span.dart';
import 'value.dart';

class NumberValueContext extends ValueContext {
  final Token NUMBER;

  NumberValueContext(this.NUMBER);

  @override
  SourceSpan get span => NUMBER.span;

  @override
  String toSource() => NUMBER.text;
}
