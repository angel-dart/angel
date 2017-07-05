import '../token.dart';
import 'package:source_span/source_span.dart';
import 'value.dart';

class BooleanValueContext extends ValueContext {
  bool _valueCache;
  final Token BOOLEAN;

  BooleanValueContext(this.BOOLEAN) {
    assert(BOOLEAN?.text == 'true' || BOOLEAN?.text == 'false');
  }

  bool get booleanValue => _valueCache ??= BOOLEAN.text == 'true';

  @override
  get value => booleanValue;

  @override
  FileSpan get span => BOOLEAN.span;

  @override
  String toSource() => BOOLEAN.text;
}
