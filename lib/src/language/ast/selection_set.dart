import '../token.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';
import 'selection.dart';

class SelectionSetContext extends Node {
  final Token LBRACE, RBRACE;
  final List<SelectionContext> selections = [];

  SelectionSetContext(this.LBRACE, this.RBRACE);

  @override
  SourceSpan get span {
    var out =
        selections.fold<SourceSpan>(LBRACE.span, (out, s) => out.union(s.span));
    return out.union(RBRACE.span);
  }

  @override
  String toSource() {
    var buf = new StringBuffer('{');

    for (int i = 0; i < selections.length; i++) {
      if (i > 0) buf.write(',');
      buf.write(selections[i].toSource());
    }

    return buf.toString() + '}';
  }
}
