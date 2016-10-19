import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';
import 'fallback.dart' as fallback;

final ABC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

main() {
  final router = new Router();
  final indexRoute = router.get('/', () => ':)');
  final fizz = router.post('/user/fizz', null);
  final deleteUserById = router.delete('/user/:id/detail', (id) => num.parse(id));

  Route lower;
  final letters = router.group('/letter///', (router) {
    lower = router
        .get('/:id([A-Za-z])', (id) => ABC.indexOf(id[0]))
        .child('////lower', handlers: [(String id) => id.toLowerCase()[0]]);

    lower.parent
        .child('/upper', handlers: [(String id) => id.toUpperCase()[0]]);
  });

  router.dumpTree(header: "ROUTER TESTS");

  test('extensible', () {
    router['two'] = 2;
    expect(router.two, equals(2));
  });

  group('fallback', fallback.main);

  test('hierarchy', () {
    expect(lower.absoluteParent, equals(router.root));
    expect(lower.parent.path, equals('letter/:id'));
    expect(lower.resolve('../upper').path, equals('letter/:id/upper'));
    expect(lower.resolve('/user/34/detail'), equals(deleteUserById));
    expect(deleteUserById.resolve('../../fizz'), equals(fizz));
  });

  test('resolve', () {
    expect(router.resolve('/'), equals(indexRoute));
    expect(router.resolve('user/1337/detail'), equals(deleteUserById));
    expect(router.resolve('/user/1337/detail'), equals(deleteUserById));
    expect(router.resolve('letter/a/lower'), equals(lower));
    expect(router.resolve('letter/2/lower'), isNull);
  });
}
