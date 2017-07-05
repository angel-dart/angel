import 'package:source_span/source_span.dart';
import '../token.dart';
import 'value.dart';

class ArrayValueContext extends ValueContext {
  final Token LBRACKET, RBRACKET;
  final List<ValueContext> values = [];

  ArrayValueContext(this.LBRACKET, this.RBRACKET);

  @override
  FileSpan get span {
    var out = values.fold<FileSpan>(LBRACKET.span, (o, v) => o.expand(v.span));
    return out.expand(RBRACKET.span);
  }

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
