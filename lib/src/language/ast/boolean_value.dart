import '../token.dart';
import 'package:source_span/src/span.dart';
import 'value.dart';

class BooleanValueContext extends ValueContext {
  final Token BOOLEAN;

  BooleanValueContext(this.BOOLEAN) {
    assert(BOOLEAN?.text == 'true' || BOOLEAN?.text == 'false');
  }

  bool get booleanValue => BOOLEAN.text == 'true';

  @override
  SourceSpan get span => BOOLEAN.span;

  @override
  String toSource() => BOOLEAN.text;
}
