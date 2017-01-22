import '../token.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';
import 'type.dart';

class ListTypeContext extends Node {
  final Token LBRACKET, RBRACKET;
  final TypeContext type;

  ListTypeContext(this.LBRACKET, this.type, this.RBRACKET);

  @override
  SourceSpan get span =>
      new SourceSpan(LBRACKET.span?.end, RBRACKET.span?.end, toSource());

  @override
  String toSource() => '[${type.toSource()}]';
}
