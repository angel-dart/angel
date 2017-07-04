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
  SourceSpan get span {
    SourceLocation start, end;

    if (typeName != null) {
      start = typeName.start;
      end = typeName.end;
    } else if (listType != null) {
      start = listType.start;
      end = listType.end;
    }

    if (EXCLAMATION != null) end = EXCLAMATION.span?.end;

    return new SourceSpan(start, end, toSource());
  }

  @override
  String toSource() {
    var buf = new StringBuffer();

    if (typeName != null) {
      buf.write(typeName.toSource());
    } else if (listType != null) {
      buf.write(listType.toSource());
    }

    if (!isNullable) buf.write('!');

    return buf.toString();
  }
}
