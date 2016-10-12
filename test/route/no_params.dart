import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

main() {
  final foo = new Route('/foo', handlers: ['bar']);
  final bar = foo.child('/bar');
  final baz = bar.child('//////baz//////', handlers: ['hello', 'world']);

  test('matching', () {
    expect(foo.children.length, equals(1));
    expect(foo.handlers.length, equals(1));
    expect(foo.handlerSequence.length, equals(1));
    expect(foo.path, equals('foo'));
    expect(foo.match('/foo'), isNotNull);
    expect(foo.match('/bar'), isNull);
    expect(foo.match('/foolish'), isNull);
    expect(foo.parent, isNull);
    expect(foo.absoluteParent, equals(foo));

    expect(bar.path, equals('foo/bar'));
    expect(bar.children.length, equals(1));
    expect(bar.handlers, isEmpty);
    expect(bar.handlerSequence.length, equals(1));
    expect(bar.match('/foo/bar'), isNotNull);
    expect(bar.match('/bar'), isNull);
    expect(bar.match('/foo/bar/2'), isNull);
    expect(bar.parent, equals(foo));
    expect(baz.absoluteParent, equals(foo));

    expect(baz.children, isEmpty);
    expect(baz.handlers.length, equals(2));
    expect(baz.handlerSequence.length, equals(3));
    expect(baz.path, equals('foo/bar/baz'));
    expect(baz.match('/foo/bar/baz'), isNotNull);
    expect(baz.match('/foo/bat/baz'), isNull);
    expect(baz.match('/foo/bar/baz/1'), isNull);
    expect(baz.parent, equals(bar));
    expect(baz.absoluteParent, equals(foo));
  });

  test('hierarchy', () {
    expect(foo.resolve('bar'), equals(bar));
    expect(foo.resolve('bar/baz'), equals(baz));

    expect(bar.resolve('..'), equals(foo));
    expect(bar.resolve('/bar/baz'), equals(baz));
    expect(bar.resolve('../bar'), equals(bar));

    expect(baz.resolve('..'), equals(bar));
    expect(baz.resolve('../..'), equals(foo));
    expect(baz.resolve('../baz'), equals(baz));
    expect(baz.resolve('../../bar'), equals(bar));
    expect(baz.resolve('../../bar/baz'), equals(baz));
    expect(baz.resolve('/bar'), equals(bar));
    expect(baz.resolve('/bar/baz'), equals(baz));
  });
}
