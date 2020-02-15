import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

main() {
  final router = Router()..get('/hello', '')..get('/user/:id', '');

  router.group('/book/:id', (router) {
    router.get('/reviews', '');
    router.get('/readers/:readerId', '');
  });

  router.mount('/color', Router()..get('/:name/shades', ''));

  setUp(router.dumpTree);

  void expectParams(String path, Map<String, dynamic> params) {
    final p = {};
    final resolved = router.resolveAll(path, path);
    print('Resolved $path => ${resolved.map((r) => r.allParams).toList()}');
    for (final result in resolved) {
      p.addAll(result.allParams);
    }
    expect(p, equals(params));
  }

  group('top-level', () {
    test('no params', () => expectParams('/hello', {}));

    test('one param', () => expectParams('/user/0', {'id': '0'}));
  });

  group('group', () {
    //test('root', () => expectParams('/book/1337', {'id': '1337'}));
    test('path', () => expectParams('/book/1337/reviews', {'id': '1337'}));
    test(
        'two params',
        () => expectParams(
            '/book/1337/readers/foo', {'id': '1337', 'readerId': 'foo'}));
  });

  test('mount',
      () => expectParams('/color/chartreuse/shades', {'name': 'chartreuse'}));
}
