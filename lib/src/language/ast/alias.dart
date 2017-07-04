import '../token.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';

class AliasContext extends Node {
  final Token NAME1, COLON, NAME2;

  AliasContext(this.NAME1, this.COLON, this.NAME2);

  /// The actual name of the value.
  String get name => NAME1.text;

  /// The aliased name of the value.
  String get alias => NAME2.text;

  @override
  SourceSpan get span =>
      new SourceSpan(NAME1.span?.start, NAME2.span?.end, toSource());

  @override
  String toSource() => '${NAME1.text}:${NAME2.text}';
}
