import 'node.dart';
import 'package:source_span/src/span.dart';
import '../token.dart';

class TypeNameContext extends Node {
  final Token NAME;

  String get name => NAME.text;

  @override
  SourceSpan get span => NAME.span;

  TypeNameContext(this.NAME);

  @override
  String toSource() => NAME.text;
}
