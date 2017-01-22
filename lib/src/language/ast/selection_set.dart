import '../token.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';
import 'selection.dart';

class SelectionSetContext extends Node {
  final Token LBRACE, RBRACE;
  final List<SelectionContext> selections = [];

  SelectionSetContext(this.LBRACE, this.RBRACE);

  @override
  SourceSpan get span =>
      new SourceSpan(LBRACE.span?.start, RBRACE.span?.end, toSource());

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
