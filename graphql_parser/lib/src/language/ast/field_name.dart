import 'package:source_span/source_span.dart';
import '../token.dart';
import 'alias.dart';
import 'node.dart';

class FieldNameContext extends Node {
  final Token NAME;
  final AliasContext alias;

  FieldNameContext(this.NAME, [this.alias]) {
    assert(NAME != null || alias != null);
  }

  String get name => NAME?.text;

  @override
  FileSpan get span => alias?.span ?? NAME.span;

  @override
  String toSource() => alias?.toSource() ?? NAME.text;
}
