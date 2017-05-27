import 'package:angel_framework/angel_framework.dart';
import 'package:test/test.dart';

class Foo {
  String name;

  Foo(String this.name);
}

main() {
  group('Utilities', () {
    Angel app;

    setUp(() {
      app = new Angel();
    });

    tearDown(() async {
      await app.close();
      app = null;
    });

    test('can use app.properties like members', () {
      app.properties['hello'] = 'world';
      app.properties['foo'] = () => 'bar';
      app.properties['Foo'] = new Foo('bar');

      expect(app.hello, equals('world'));
      expect(app.foo(), equals('bar'));
      expect(app.Foo.name, equals('bar'));
    });
  });
}
