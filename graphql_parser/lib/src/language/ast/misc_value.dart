import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';
import 'node.dart';

class NullValueContext extends InputValueContext<Null> {
  final Token NULL;

  NullValueContext(this.NULL);

  @override
  FileSpan get span => NULL.span;

  @override
  Null computeValue(Map<String, dynamic> variables) => null;
}

class EnumValueContext extends InputValueContext<String> {
  final Token NAME;

  EnumValueContext(this.NAME);

  @override
  FileSpan get span => NAME.span;

  @override
  String computeValue(Map<String, dynamic> variables) => NAME.span.text;
}

class ObjectValueContext extends InputValueContext<Map<String, dynamic>> {
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
  Map<String, dynamic> computeValue(Map<String, dynamic> variables) {
    if (fields.isEmpty) {
      return <String, dynamic>{};
    } else {
      return fields.fold<Map<String, dynamic>>(<String, dynamic>{},
          (map, field) {
        return map..[field.NAME.text] = field.value.computeValue(variables);
      });
    }
  }
}

class ObjectFieldContext extends Node {
  final Token NAME;
  final Token COLON;
  final InputValueContext value;

  ObjectFieldContext(this.NAME, this.COLON, this.value);

  @override
  FileSpan get span => NAME.span.expand(COLON.span).expand(value.span);
}
