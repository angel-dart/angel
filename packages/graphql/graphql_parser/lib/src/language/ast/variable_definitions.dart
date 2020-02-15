import '../token.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';
import 'variable_definition.dart';

/// A set of variable definitions in a GraphQL operation.
class VariableDefinitionsContext extends Node {
  /// The source tokens.
  final Token lParenToken, rParenToken;

  /// The variables defined in this node.
  final List<VariableDefinitionContext> variableDefinitions = [];

  VariableDefinitionsContext(this.lParenToken, this.rParenToken);

  /// Use [lParenToken] instead.
  @deprecated
  Token get LPAREN => lParenToken;

  /// Use [rParenToken] instead.
  @deprecated
  Token get RPAREN => rParenToken;

  @override
  FileSpan get span {
    var out = variableDefinitions.fold<FileSpan>(
        lParenToken.span, (o, v) => o.expand(v.span));
    return out.expand(rParenToken.span);
  }
}
