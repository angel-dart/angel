import '../token.dart';
import 'package:source_span/src/span.dart';
import 'value.dart';

class ArrayValueContext extends ValueContext {
  final Token LBRACKET, RBRACKET;
  final List<ValueContext> values = [];

  ArrayValueContext(this.LBRACKET, this.RBRACKET);

  @override
  SourceSpan get span =>
      new SourceSpan(LBRACKET.span?.end, RBRACKET.span?.end, toSource());

  @override
  List get value => values.map((v) => v.value).toList();

  @override
  String toSource() {
    var buf = new StringBuffer('[');

    for (int i = 0; i < values.length; i++) {
      if (i > 0) buf.write(',');
      buf.write(values[i].toSource());
    }

    return buf.toString() + ']';
  }
}
