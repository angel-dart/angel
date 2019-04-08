import 'dart:typed_data';

import 'package:test/test.dart';
import 'models/with_enum.dart';

const WithEnum aWithEnum = const WithEnum(type: WithEnumType.a);
const WithEnum aWithEnum2 = const WithEnum(type: WithEnumType.a);

void main() {
  test('enum serializes to int', () {
    var w = new WithEnum(type: WithEnumType.b).toJson();
    expect(w[WithEnumFields.type], WithEnumType.values.indexOf(WithEnumType.b));
  });

  test('enum serializes null if null', () {
    var w = new WithEnum(type: null).toJson();
    expect(w[WithEnumFields.type], null);
  });

  test('enum deserializes to default value from null', () {
    var map = {WithEnumFields.type: null};
    var w = WithEnumSerializer.fromMap(map);
    expect(w.type, WithEnumType.b);
  });

  test('enum deserializes from int', () {
    var map = {
      WithEnumFields.type: WithEnumType.values.indexOf(WithEnumType.b)
    };
    var w = WithEnumSerializer.fromMap(map);
    expect(w.type, WithEnumType.b);
  });

  test('enum deserializes from value', () {
    var map = {WithEnumFields.type: WithEnumType.c};
    var w = WithEnumSerializer.fromMap(map);
    expect(w.type, WithEnumType.c);
  });

  test('equality', () {
    expect(
        new WithEnum(type: WithEnumType.a), new WithEnum(type: WithEnumType.a));
    expect(new WithEnum(type: WithEnumType.a),
        isNot(new WithEnum(type: WithEnumType.b)));
  });

  test('const', () {
    expect(identical(aWithEnum, aWithEnum2), true);
  });

  test('uint8list', () {
    var ee = new WithEnum(
        imageBytes:
            new Uint8List.fromList(new List<int>.generate(1000, (i) => i)));
    var eeMap = ee.toJson();
    print(ee);
    var ef = WithEnumSerializer.fromMap(eeMap);
    expect(ee.copyWith(), ee);
    expect(ef, ee);
  });
}
