import 'package:source_span/source_span.dart';
import '../token.dart';
import 'constant.dart';
import 'input_value.dart';

class ListValueContext extends ValueContext {
  final Token LBRACKET, RBRACKET;
  final List<ValueContext> values = [];

  ListValueContext(this.LBRACKET, this.RBRACKET);

  @override
  FileSpan get span {
    var out = values.fold<FileSpan>(LBRACKET.span, (o, v) => o.expand(v.span));
    return out.expand(RBRACKET.span);
  }

  @override
  List get value => values.map((v) => v.value).toList();
}
