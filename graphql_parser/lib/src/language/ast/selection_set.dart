import 'package:source_span/source_span.dart';

import '../token.dart';
import 'node.dart';
import 'selection.dart';

class SelectionSetContext extends Node {
  final Token LBRACE, RBRACE;
  final List<SelectionContext> selections = [];

  SelectionSetContext(this.LBRACE, this.RBRACE);

  factory SelectionSetContext.merged(List<SelectionContext> selections) =
      _MergedSelectionSetContext;

  @override
  FileSpan get span {
    var out =
        selections.fold<FileSpan>(LBRACE.span, (out, s) => out.expand(s.span));
    return out.expand(RBRACE.span);
  }
}

class _MergedSelectionSetContext extends SelectionSetContext {
  final List<SelectionContext> selections;

  _MergedSelectionSetContext(this.selections) : super(null, null);

  @override
  FileSpan get span =>
      selections.map((s) => s.span).reduce((a, b) => a.expand(b));
}
