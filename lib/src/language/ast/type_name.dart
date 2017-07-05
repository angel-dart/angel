import 'node.dart';
import 'package:source_span/source_span.dart';
import '../token.dart';

class TypeNameContext extends Node {
  final Token NAME;

  String get name => NAME.text;

  @override
  FileSpan get span => NAME.span;

  TypeNameContext(this.NAME);

  @override
  String toSource() => NAME.text;
}
