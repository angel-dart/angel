import 'dart:convert';
import 'package:test/test.dart';
import 'models/has_map.dart';

void main() {
  var m = HasMap(value: {'foo': 'bar'});
  print(json.encode(m));

  test('json', () {
    expect(json.encode(m), r'{"value":"{\"foo\":\"bar\"}"}');
  });

  test('decode', () {
    var mm = json.decode(r'{"value":"{\"foo\":\"bar\"}"}') as Map;
    var mmm = HasMapSerializer.fromMap(mm);
    expect(mmm, m);
  });
}
