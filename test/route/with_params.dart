import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

main() {
  final foo = new Router().root;
  final fooById = foo.child(':id((?!bar)[0-9]+)', handlers: ['bar']);
  final bar = fooById.child('bar');
  final baz = bar.child('//////baz//////', handlers: ['hello', 'world']);
  final bazById = baz.child(':bazId([A-Za-z]+)');
  new Router(root: foo).dumpTree();

  test('matching', () {
    expect(fooById.children.length, equals(1));
    expect(fooById.handlers.length, equals(1));
    expect(fooById.handlerSequence.length, equals(1));
    expect(fooById.path, equals(':id'));
    expect(fooById.match('/2'), isNotNull);
    expect(fooById.match('/aaa'), isNull);
    expect(fooById.match('/bar'), isNull);
    expect(fooById.match('lish'), isNull);
    expect(fooById.parent, equals(foo));
    expect(fooById.absoluteParent, equals(foo));

    expect(bar.path, equals(':id/bar'));
    expect(bar.children.length, equals(1));
    expect(bar.handlers, isEmpty);
    expect(bar.handlerSequence.length, equals(1));
    expect(bar.match('/2/bar'), isNotNull);
    expect(bar.match('/bar'), isNull);
    expect(bar.match('/a/bar'), isNull);
    expect(bar.parent, equals(fooById));
    expect(baz.absoluteParent, equals(foo));

    expect(baz.children.length, equals(1));
    expect(baz.handlers.length, equals(2));
    expect(baz.handlerSequence.length, equals(3));
    expect(baz.path, equals(':id/bar/baz'));
    expect(baz.match('/2A/bar/baz'), isNull);
    expect(baz.match('/2/bar/baz'), isNotNull);
    expect(baz.match('/1337/bar/baz'), isNotNull);
    expect(baz.match('/bat/baz'), isNull);
    expect(baz.match('/bar/baz/1'), isNull);
    expect(baz.parent, equals(bar));
    expect(baz.absoluteParent, equals(foo));
  });

  test('hierarchy', () {
    expect(fooById.resolve('/2'), equals(fooById));

    expect(fooById.resolve('/2/bar'), equals(bar));
    expect(fooById.resolve('/bar'), isNull);
    expect(fooById.resolve('/a/bar'), isNull);
    expect(fooById.resolve('1337/bar/baz'), equals(baz));

    expect(bar.resolve('..'), equals(fooById));

    new Router(root: bar.parent).dumpTree(header: "POOP");
    expect(bar.parent.resolve('bar/baz'), equals(baz));
    expect(bar.resolve('/2/bar/baz'), equals(baz));
    expect(bar.resolve('../bar'), equals(bar));

    expect(baz.resolve('..'), equals(bar));
    expect(baz.resolve('../..'), equals(fooById));
    expect(baz.resolve('../baz'), equals(baz));
    expect(baz.resolve('../../bar'), equals(bar));
    expect(baz.resolve('../../bar/baz'), equals(baz));
    expect(baz.resolve('/2/bar'), equals(bar));
    expect(baz.resolve('/1337/bar/baz'), equals(baz));

    expect(bar.resolve('/2/bar/baz/e'), equals(bazById));
    expect(bar.resolve('baz/e'), equals(bazById));
    expect(fooById.resolve('/2/bar/baz/e'), equals(bazById));
    expect(fooById.resolve('/2/bar/baz/2'), isNull);
    expect(fooById.resolve('/2a/bar/baz/e'), isNull);
  });
}
