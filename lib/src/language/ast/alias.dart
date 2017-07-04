import '../token.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';

class AliasContext extends Node {
  final Token NAME1, COLON, NAME2;

  AliasContext(this.NAME1, this.COLON, this.NAME2);

  /// The aliased name of the value.
  String get alias => NAME1.text;

  /// The actual name of the value.
  String get name => NAME2.text;

  @override
  SourceSpan get span => NAME1.span.union(COLON.span).union(NAME2.span);

  @override
  String toSource() => '${NAME1.text}:${NAME2.text}';
}
