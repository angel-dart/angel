library jael.src.text.parselet;

import '../../ast/ast.dart';
import '../parser.dart';
part 'infix.dart';
part 'prefix.dart';

abstract class PrefixParselet {
  Expression parse(Parser parser, Token token);
}

abstract class InfixParselet {
  int get precedence;
  Expression parse(Parser parser, Expression left, Token token);
}
