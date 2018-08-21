@GenerateReflector(types: [Artist])
library angel_container_generator_test;

import 'package:angel_container/angel_container.dart';
import 'package:test/test.dart';

part 'reflector.reflector.g.dart';

void main() {
  var reflector = const AngelContainerGeneratorTestReflector();

  group('reflectClass', () {
    var mirror = reflector.reflectClass(Artist);

    test('name', () {
      expect(mirror.name, 'Artist');
    });
  });
}

class Artist {}
