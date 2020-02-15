import 'package:source_span/source_span.dart';
import '../token.dart';
import 'definition.dart';
import 'directive.dart';
import 'selection_set.dart';
import 'variable_definitions.dart';

/// An executable GraphQL operation definition.
class OperationDefinitionContext extends ExecutableDefinitionContext {
  /// The source tokens.
  final Token typeToken, nameToken;

  /// The variables defined in the operation.
  final VariableDefinitionsContext variableDefinitions;

  /// Any directives affixed to this operation.
  final List<DirectiveContext> directives = [];

  /// The selections to be applied to an object resolved in this operation.
  final SelectionSetContext selectionSet;

  /// Whether this operation is a `mutation`.
  bool get isMutation => typeToken?.text == 'mutation';

  /// Whether this operation is a `subscription`.
  bool get isSubscription => typeToken?.text == 'subscription';

  /// Whether this operation is a `query`.
  bool get isQuery => typeToken?.text == 'query' || typeToken == null;

  /// The [String] value of the [nameToken].
  String get name => nameToken?.text;

  /// Use [nameToken] instead.
  @deprecated
  Token get NAME => nameToken;

  /// Use [typeToken] instead.
  @deprecated
  Token get TYPE => typeToken;

  OperationDefinitionContext(this.typeToken, this.nameToken,
      this.variableDefinitions, this.selectionSet) {
    assert(typeToken == null ||
        typeToken.text == 'query' ||
        typeToken.text == 'mutation' ||
        typeToken.text == 'subscription');
  }

  @override
  FileSpan get span {
    if (typeToken == null) return selectionSet.span;
    var out = nameToken == null
        ? typeToken.span
        : typeToken.span.expand(nameToken.span);
    out = directives.fold<FileSpan>(out, (o, d) => o.expand(d.span));
    return out.expand(selectionSet.span);
  }
}
