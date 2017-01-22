import '../token.dart';
import 'package:source_span/src/span.dart';
import 'value.dart';

class BooleanValueContext extends ValueContext {
  final Token BOOLEAN;

  BooleanValueContext(this.BOOLEAN);

  @override
  SourceSpan get span => BOOLEAN.span;

  @override
  String toSource() => BOOLEAN.text;
}
