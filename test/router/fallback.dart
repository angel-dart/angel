import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

bool checkPost(Route route) => route.method == "POST";

main() {
  final router = new Router();

  final userById = router.group('/user', (router) {
    router.get('/:id', (id) => 'User $id');
  }).resolve(':id');

  final fallback = router.get('*', () => 'fallback');

  test('resolve', () {
    expect(router.resolveOnRoot('/foo'), equals(fallback));
    expect(router.resolveOnRoot('/user/:id'), equals(userById));
    expect(router.resolveOnRoot('/user/:id', filter: checkPost), isNull);
  });
}
