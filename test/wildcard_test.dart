import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

void main() {
  var router = Router();
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
    var result =
        router.resolveAbsolute('/isnt/she/fierce%20harmonica%solo').first;
    expect(result.handlers, ['lovely']);
  });

  test('tail explicitly set intermediate', () {
    var results = router.resolveAbsolute('/songs/in_the/key');
    var result = results.first;
    print(results.map((r) => {r.route.path: r.tail}));
    expect(result.tail, 'in_the');
  });

  test('tail explicitly set at end', () {
    var results = router.resolveAbsolute('/isnt/she/epic');
    var result = results.first;
    print(results.map((r) => {r.route.path: r.tail}));
    expect(result.tail, 'epic');
  });

  test('tail with trailing', () {
    var results = router.resolveAbsolute('/isnt/she/epic/fail');
    var result = results.first;
    print(results.map((r) => {r.route.path: r.tail}));
    expect(result.tail, 'epic/fail');
  });
}
