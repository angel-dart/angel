import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

void main() {
  var router = new Router();
  router.get('/songs/*/key', 'of life');
  router.get('/isnt/she/*', 'lovely');
  router.all('*', 'stevie');

  test('match until end if * is last', () {
    var result = router.resolveAbsolute('/wonder').first;
    expect(result.handlers, ['stevie']);
  });

  test('match if not last', () {
    var result = router.resolveAbsolute('/songs/what/key').first;
    expect(result.handlers, ['of life']);
  });

  test('match if segments before', () {
    var result = router.resolveAbsolute('/isnt/she/fierce%20harmonica%solo').first;
    expect(result.handlers, ['lovely']);
  });
}