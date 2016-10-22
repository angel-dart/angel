import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

final String ARTIFICIAL_INDEX = 'artificial index';

tattle(x) => 'This ${x.runtimeType}.debug = ${x.debug}';
tattleAll(x) => x.map(tattle).join('\n');

main() {
  final parent = new Router(debug: true);
  final child = new Router(debug: true);
  Route a, b, c;

  a = child.get('a', ['c']);
  child.group('b', (router) {
    b = router.get('/', ARTIFICIAL_INDEX);
    c = router.post('c', 'Hello nested');
  });

  parent.mount('child', child);
  parent.dumpTree(header: tattleAll([parent, child, a]));

  group('no params', () {
    test('resolve', () {
      expect(child.resolve('a'), equals(a));
      expect(child.resolve('b'), equals(b));
      expect(child.resolve('b/c'), equals(c));

      expect(parent.resolve('child/a'), equals(a));
      expect(parent.resolve('a'), isNull);
      expect(parent.resolve('child/b'), equals(b));
      expect(parent.resolve('child/b/c'), equals(c));
    });
  });
}
