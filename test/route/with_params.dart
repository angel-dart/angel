import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

main() {
  final foo = new Route.build('/foo/:id([0-9]+)', handlers: ['bar']);
  final bar = foo.child('/bar');
  final baz = bar.child('//////baz//////', handlers: ['hello', 'world']);
  new Router(foo).dumpTree();

  test('matching', () {
    expect(foo.children.length, equals(1));
    expect(foo.handlers.length, equals(1));
    expect(foo.handlerSequence.length, equals(1));
    expect(foo.path, equals('foo/:id'));
    expect(foo.match('/foo/2'), isNotNull);
    expect(foo.match('/foo/aaa'), isNull);
    expect(foo.match('/bar'), isNull);
    expect(foo.match('/foolish'), isNull);
    expect(foo.parent, equals(base));
    expect(foo.absoluteParent, equals(base));

    expect(bar.path, equals('foo/:id/bar'));
    expect(bar.children.length, equals(1));
    expect(bar.handlers, isEmpty);
    expect(bar.handlerSequence.length, equals(1));
    expect(bar.match('/foo/2/bar'), isNotNull);
    expect(bar.match('/bar'), isNull);
    expect(bar.match('/foo/a/bar'), isNull);
    expect(bar.parent, equals(foo));
    expect(baz.absoluteParent, equals(base));

    expect(baz.children, isEmpty);
    expect(baz.handlers.length, equals(2));
    expect(baz.handlerSequence.length, equals(3));
    expect(baz.path, equals('foo/:id/bar/baz'));
    expect(baz.match('/foo/2A/bar/baz'), isNull);
    expect(baz.match('/foo/2/bar/baz'), isNotNull);
    expect(baz.match('/foo/1337/bar/baz'), isNotNull);
    expect(baz.match('/foo/bat/baz'), isNull);
    expect(baz.match('/foo/bar/baz/1'), isNull);
    expect(baz.parent, equals(bar));
    expect(baz.absoluteParent, equals(base));
  });

  test('hierarchy', () {
    expect(foo.resolve('/foo/2'), equals(foo));

    expect(foo.resolve('/foo/2/bar'), equals(bar));
    expect(foo.resolve('/foo/bar'), isNull);
    expect(foo.resolve('foo/1337/bar/baz'), equals(baz));

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
