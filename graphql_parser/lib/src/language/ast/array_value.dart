import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';

class ListValueContext extends InputValueContext {
  final Token LBRACKET, RBRACKET;
  final List<InputValueContext> values = [];

  ListValueContext(this.LBRACKET, this.RBRACKET);

  @override
  FileSpan get span {
    var out = values.fold<FileSpan>(LBRACKET.span, (o, v) => o.expand(v.span));
    return out.expand(RBRACKET.span);
  }

  @override
  computeValue(Map<String, dynamic> variables) {
    return values.map((v) => v.computeValue(variables)).toList();
  }
}
