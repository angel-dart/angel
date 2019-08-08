import 'package:source_span/source_span.dart';
import 'input_value.dart';
import '../token.dart';

class BooleanValueContext extends InputValueContext<bool> {
  bool _valueCache;
  final Token BOOLEAN;

  BooleanValueContext(this.BOOLEAN) {
    assert(BOOLEAN?.text == 'true' || BOOLEAN?.text == 'false');
  }

  bool get booleanValue => _valueCache ??= BOOLEAN.text == 'true';

  @override
  FileSpan get span => BOOLEAN.span;

  @override
  bool computeValue(Map<String, dynamic> variables) => booleanValue;
}
