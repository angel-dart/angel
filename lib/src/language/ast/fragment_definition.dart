import '../token.dart';
import 'definition.dart';
import 'directive.dart';
import 'package:source_span/src/span.dart';
import 'selection_set.dart';
import 'type_condition.dart';

class FragmentDefinitionContext extends DefinitionContext {
  final Token FRAGMENT, NAME, ON;
  final TypeConditionContext typeCondition;
  final List<DirectiveContext> directives = [];
  final SelectionSetContext selectionSet;

  String get name => NAME.text;

  FragmentDefinitionContext(
      this.FRAGMENT, this.NAME, this.ON, this.typeCondition, this.selectionSet);

  @override
  SourceSpan get span =>
      new SourceSpan(FRAGMENT.span?.start, selectionSet.end, toSource());

  @override
  String toSource() =>
      'fragment ${NAME.text} on ' +
      typeCondition.toSource() +
      directives.map((d) => d.toSource()).join() +
      selectionSet.toSource();
}
