import 'package:angel_container/angel_container.dart';
import 'package:test/test.dart';

void main() {
  Container container;

  setUp(() {
    container = new Container(const EmptyReflector());
    container.registerNamedSingleton('foo', new Foo(bar: 'baz'));
  });

  test('fetch by name', () {
    expect(container.findByName<Foo>('foo').bar, 'baz');
  });

  test('cannot redefine', () {
    expect(() => container.registerNamedSingleton('foo', new Foo(bar: 'quux')),
        throwsStateError);
  });

  test('throws on unknown name', () {
    expect(() => container.findByName('bar'), throwsStateError);
  });

  test('throws on incorrect type', () {
    expect(() => container.findByName<List<String>>('foo'), throwsA(anything));
  });
}

class Foo {
  final String bar;

  Foo({this.bar});
}
