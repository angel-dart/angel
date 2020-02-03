import '../token.dart';
import 'directive.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';
import 'selection_set.dart';
import 'type_condition.dart';

/// An inline fragment, which typically appears in a [SelectionSetContext].
class InlineFragmentContext extends Node {
  /// The source tokens.
  final Token ellipsisToken, onToken;

  /// The type which this fragment matches.
  final TypeConditionContext typeCondition;

  /// Any directives affixed to this inline fragment.
  final List<DirectiveContext> directives = [];

  /// The selections applied when the [typeCondition] is met.
  final SelectionSetContext selectionSet;

  InlineFragmentContext(
      this.ellipsisToken, this.onToken, this.typeCondition, this.selectionSet);

  /// Use [ellipsisToken] instead.
  @deprecated
  Token get ELLIPSIS => ellipsisToken;

  /// Use [onToken] instead.
  @deprecated
  Token get ON => onToken;

  @override
  FileSpan get span {
    var out =
        ellipsisToken.span.expand(onToken.span).expand(typeCondition.span);
    out = directives.fold<FileSpan>(out, (o, d) => o.expand(d.span));
    return out.expand(selectionSet.span);
  }
}
