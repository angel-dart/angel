import 'package:source_span/source_span.dart';
import 'package:symbol_table/symbol_table.dart';
import 'ast_node.dart';
import 'token.dart';

abstract class Expression extends AstNode {
  compute(SymbolTable scope);
}

abstract class Literal extends Expression {}

class Negation extends Expression {
  final Token exclamation;
  final Expression expression;

  Negation(this.exclamation, this.expression);

  @override
  FileSpan get span {
    return exclamation.span.expand(expression.span);
  }

  @override
  compute(SymbolTable scope) {
    var v = expression.compute(scope) as bool;

    if (scope.resolve('!strict!')?.value == false) {
      v = v == true;
    }

    return !v;
  }
}
