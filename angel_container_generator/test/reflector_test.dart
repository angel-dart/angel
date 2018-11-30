import 'package:angel_container_generator/angel_container_generator.dart';
import 'package:test/test.dart';
import 'reflector_test.reflectable.dart';

void main() {
  var reflector = const GeneratedReflector();
  initializeReflectable();

  group('reflectClass', () {
    var mirror = reflector.reflectClass(Artist);

    test('name', () {
      expect(mirror.name, 'Artist');
    });
  });
}

@contained
class Artist {
  String name;
}
