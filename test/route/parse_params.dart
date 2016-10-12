import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

p(x) {
  print(x);
  return x;
}

main() {
  final foo = new Route('/foo/:id');
  final bar = foo.child('/bar/:barId/baz');

  test('make uri', () {
    expect(p(foo.makeUri({'id': 1337})), equals('foo/1337'));
    expect(p(bar.makeUri({'id': 1337, 'barId': 12})),
        equals('foo/1337/bar/12/baz'));
  });

  test('parse', () {
    final fooParams = foo.parseParameters('foo/1337/////');
    expect(p(fooParams), equals({'id': 1337}));

    final barParams = bar.parseParameters('/////foo/1337/bar/12/baz');
    expect(p(barParams), equals({'id': 1337, 'barId': 12}));
  });
}
