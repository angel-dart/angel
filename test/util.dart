import 'package:angel_framework/angel_framework.dart';
import 'package:test/test.dart';

class Foo {
  String name;

  Foo(String this.name);
}

main() {
  group('Utilities', () {
    Angel angel;

    setUp(() {
      angel = new Angel();
    });

    tearDown(() {
      angel = null;
    });

    test('can use app.properties like members', () {
      angel.properties['hello'] = 'world';
      angel.properties['foo'] = () => 'bar';
      angel.properties['Foo'] = new Foo('bar');

      /**
      expect(angel.hello, equals('world'));
      expect(angel.foo(), equals('bar'));
      expect(angel.Foo.name, equals('bar'));
      */
    });
  });
}
