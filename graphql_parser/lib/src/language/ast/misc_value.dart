import 'package:source_span/source_span.dart';

import '../token.dart';
import 'node.dart';
import 'value.dart';

class NullValueContext extends ValueContext<Null> {
  final Token NULL;

  NullValueContext(this.NULL);

  @override
  FileSpan get span => NULL.span;

  @override
  Null get value => null;
}

class EnumValueContext extends ValueContext<String> {
  final Token NAME;

  EnumValueContext(this.NAME);

  @override
  FileSpan get span => NAME.span;

  @override
  String get value => NAME.span.text;
}

class ObjectValueContext extends ValueContext<Map<String, dynamic>> {
  final Token LBRACE;
  final List<ObjectFieldContext> fields;
  final Token RBRACE;

  ObjectValueContext(this.LBRACE, this.fields, this.RBRACE);

  @override
  FileSpan get span {
    var left = LBRACE.span;

    for (var field in fields) {
      left = left.expand(field.span);
    }

    return left.expand(RBRACE.span);
  }

  @override
  Map<String, dynamic> get value {
    if (fields.isEmpty) {
      return <String, dynamic>{};
    } else {
      return fields.fold<Map<String, dynamic>>(<String, dynamic>{},
          (map, field) {
        return map..[field.NAME.text] = field.value.value;
      });
    }
  }
}

class ObjectFieldContext extends Node {
  final Token NAME;
  final Token COLON;
  final ValueContext value;

  ObjectFieldContext(this.NAME, this.COLON, this.value);

  @override
  FileSpan get span => NAME.span.expand(COLON.span).expand(value.span);
}
