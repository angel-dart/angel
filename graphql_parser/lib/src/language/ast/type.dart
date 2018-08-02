import 'package:source_span/source_span.dart';
import '../token.dart';
import 'list_type.dart';
import 'node.dart';
import 'type_name.dart';

class TypeContext extends Node {
  final Token EXCLAMATION;
  final TypeNameContext typeName;
  final ListTypeContext listType;

  bool get isNullable => EXCLAMATION == null;

  TypeContext(this.typeName, this.listType, [this.EXCLAMATION]) {
    assert(typeName != null || listType != null);
  }

  @override
  FileSpan get span {
    var out = typeName?.span ?? listType.span;
    return EXCLAMATION != null ? out.expand(EXCLAMATION.span) : out;
  }
}
