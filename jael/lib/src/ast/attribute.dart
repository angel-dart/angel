import 'package:source_span/source_span.dart';
import 'ast_node.dart';
import 'expression.dart';
import 'identifier.dart';
import 'string.dart';
import 'token.dart';

class Attribute extends AstNode {
  final Identifier id;
  final StringLiteral string;
  final Token equals, nequ;
  final Expression value;

  Attribute(this.id, this.string, this.equals, this.nequ, this.value);

  bool get isRaw => nequ != null;

  Expression get nameNode => id ?? string;

  String get name => string?.value ?? id.name;

  @override
  FileSpan get span {
    if (equals == null) return nameNode.span;
    return nameNode.span.expand(equals?.span ?? nequ.span).expand(value.span);
  }
}
