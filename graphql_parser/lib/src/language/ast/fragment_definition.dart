import '../token.dart';
import 'definition.dart';
import 'directive.dart';
import 'package:source_span/source_span.dart';
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
  FileSpan get span {
    var out = FRAGMENT.span
        .expand(NAME.span)
        .expand(ON.span)
        .expand(typeCondition.span);
    out = directives.fold<FileSpan>(out, (o, d) => o.expand(d.span));
    return out.expand(selectionSet.span);
  }
}
