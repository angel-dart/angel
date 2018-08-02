import '../token.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';
import 'type.dart';

class ListTypeContext extends Node {
  final Token LBRACKET, RBRACKET;
  final TypeContext type;

  ListTypeContext(this.LBRACKET, this.type, this.RBRACKET);

  @override
  FileSpan get span => LBRACKET.span.expand(type.span).expand(RBRACKET.span);

  @override
  String toSource() => '[${type.toSource()}]';
}
