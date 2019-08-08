import 'package:source_span/source_span.dart';

import '../token.dart';
import 'node.dart';
import 'selection.dart';

/// A set of GraphQL selections - fields, fragments, or inline fragments.
class SelectionSetContext extends Node {
  /// The source tokens.
  final Token lBraceToken, rBraceToken;

  /// The selections to be applied.
  final List<SelectionContext> selections = [];

  SelectionSetContext(this.lBraceToken, this.rBraceToken);

  /// A synthetic [SelectionSetContext] produced from a set of [selections].
  factory SelectionSetContext.merged(List<SelectionContext> selections) =
      _MergedSelectionSetContext;

  /// Use [lBraceToken] instead.
  @deprecated
  Token get LBRACE => lBraceToken;

  /// Use [rBraceToken] instead.
  @deprecated
  Token get RBRACE => rBraceToken;

  @override
  FileSpan get span {
    var out = selections.fold<FileSpan>(
        lBraceToken.span, (out, s) => out.expand(s.span));
    return out.expand(rBraceToken.span);
  }
}

class _MergedSelectionSetContext extends SelectionSetContext {
  final List<SelectionContext> selections;

  _MergedSelectionSetContext(this.selections) : super(null, null);

  @override
  FileSpan get span =>
      selections.map((s) => s.span).reduce((a, b) => a.expand(b));
}
