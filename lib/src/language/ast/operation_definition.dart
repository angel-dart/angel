import '../token.dart';
import 'definition.dart';
import 'directive.dart';
import 'package:source_span/source_span.dart';
import 'selection_set.dart';
import 'variable_definitions.dart';

class OperationDefinitionContext extends DefinitionContext {
  final Token TYPE, NAME;
  final VariableDefinitionsContext variableDefinitions;
  final List<DirectiveContext> directives = [];
  final SelectionSetContext selectionSet;

  bool get isMutation => TYPE?.text == 'mutation';
  bool get isQuery => TYPE?.text == 'query';

  String get name => NAME?.text;

  OperationDefinitionContext(
      this.TYPE, this.NAME, this.variableDefinitions, this.selectionSet) {
    assert(TYPE == null || TYPE.text == 'query' || TYPE.text == 'mutation');
  }

  @override
  FileSpan get span {
    if (TYPE == null) return selectionSet.span;
    var out = TYPE.span.expand(NAME.span);
    out = directives.fold<FileSpan>(out, (o, d) => o.expand(d.span));
    return out.expand(selectionSet.span);
  }

  @override
  String toSource() {
    if (TYPE == null) return selectionSet.toSource();
    return '${TYPE.text} ${NAME.text} ${variableDefinitions.toSource()} ' +
        directives.map((d) => d.toSource()).join() +
        ' ${selectionSet.toSource()}';
  }
}
