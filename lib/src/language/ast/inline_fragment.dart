import '../token.dart';
import 'directive.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';
import 'selection_set.dart';
import 'type_condition.dart';

class InlineFragmentContext extends Node {
  final Token ELLIPSIS, ON;
  final TypeConditionContext typeCondition;
  final List<DirectiveContext> directives = [];
  final SelectionSetContext selectionSet;

  InlineFragmentContext(
      this.ELLIPSIS, this.ON, this.typeCondition, this.selectionSet);

  @override
  FileSpan get span {
    var out = ELLIPSIS.span.expand(ON.span).expand(typeCondition.span);
    out = directives.fold<FileSpan>(out, (o, d) => o.expand(d.span));
    return out.expand(selectionSet.span);
  }

  @override
  String toSource() =>
      '...on${typeCondition.toSource()}' +
      directives.map((d) => d.toSource()).join() +
      selectionSet.toSource();
}
