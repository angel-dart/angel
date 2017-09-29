import 'package:symbol_table/symbol_table.dart';
import 'ast_node.dart';

abstract class Expression extends AstNode {
  compute(SymbolTable scope);
}

abstract class Literal extends Expression {}