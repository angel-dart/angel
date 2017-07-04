import '../token.dart';
import 'alias.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';

class FieldNameContext extends Node {
  final Token NAME;
  final AliasContext alias;

  FieldNameContext(this.NAME, [this.alias]) {
    assert(NAME != null || alias != null);
  }

  String get name => NAME?.text;

  @override
  SourceSpan get span => alias?.span ?? NAME.span;

  @override
  String toSource() => alias?.toSource() ?? NAME.text;
}
