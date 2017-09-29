import 'dart:mirrors';
import 'package:source_span/source_span.dart';
import 'package:symbol_table/symbol_table.dart';
import 'expression.dart';
import 'identifier.dart';
import 'token.dart';

class MemberExpression extends Expression {
  final Expression expression;
  final Token dot;
  final Identifier name;

  MemberExpression(this.expression, this.dot, this.name);

  @override
  compute(SymbolTable scope) {
    var target = expression.compute(scope);
    return reflect(target).getField(new Symbol(name.name)).reflectee;
  }

  @override
  FileSpan get span => expression.span.expand(dot.span).expand(name.span);
}
