import 'package:source_span/source_span.dart';
import 'ast_node.dart';
import 'expression.dart';
import 'identifier.dart';
import 'token.dart';

class Attribute extends AstNode {
  final Identifier name;
  final Token equals;
  final Expression value;

  Attribute(this.name, this.equals, this.value);

  @override
  FileSpan get span {
    if (equals == null) return name.span;
    return name.span.expand(equals.span).expand(value.span);
  }
}
