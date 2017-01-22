import '../token.dart';
import 'directive.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';
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
  SourceSpan get span =>
      new SourceSpan(ELLIPSIS.span?.start, selectionSet.end, toSource());

  @override
  String toSource() =>
      '...on${typeCondition.toSource()}' +
      directives.map((d) => d.toSource()).join() +
      selectionSet.toSource();
}
