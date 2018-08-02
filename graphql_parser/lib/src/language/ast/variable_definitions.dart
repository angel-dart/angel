import '../token.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';
import 'variable_definition.dart';

class VariableDefinitionsContext extends Node {
  final Token LPAREN, RPAREN;
  final List<VariableDefinitionContext> variableDefinitions = [];

  VariableDefinitionsContext(this.LPAREN, this.RPAREN);

  @override
  FileSpan get span {
    var out = variableDefinitions.fold<FileSpan>(
        LPAREN.span, (o, v) => o.expand(v.span));
    return out.expand(RPAREN.span);
  }

  @override
  String toSource() {
    var buf = new StringBuffer('(');

    for (int i = 0; i < variableDefinitions.length; i++) {
      if (i > 0) buf.write(',');
      buf.write(variableDefinitions[i].toSource());
    }

    buf.write(')');
    return buf.toString();
  }
}
