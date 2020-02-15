import 'package:test/test.dart';
import 'models/goat.dart';

void main() {
  group('constructor', () {
    test('int default', () {
      expect(Goat().integer, 34);
    });

    test('list default', () {
      expect(Goat().list, [34, 35]);
    });
  });

  group('from map', () {
    test('int default', () {
      expect(GoatSerializer.fromMap({}).integer, 34);
    });

    test('list default', () {
      expect(GoatSerializer.fromMap({}).list, [34, 35]);
    });
  });
}
