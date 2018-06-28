import 'dart:math';
import 'package:code_buffer/code_buffer.dart';
import 'package:jael/jael.dart' as jael;
import 'package:symbol_table/symbol_table.dart';
import 'package:test/test.dart';

void main() {
  test('render into div', () {
    var template = '''
    <element name="square-root">
      The square root of {{ n }} is {{ sqrt(n) }}.
    </element>
    <square-root n="16" />
    ''';

    var html = render(template, {'sqrt': sqrt});
  });
}

String render(String template, [Map<String, dynamic> values]) {
  var doc = jael.parseDocument(template, onError: (e) => throw e);
  var buffer = new CodeBuffer();
  const jael.Renderer().render(doc, buffer, new SymbolTable(values: values));
  return buffer.toString();
}