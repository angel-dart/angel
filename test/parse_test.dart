import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

void main() {
  var router = new Router()
    ..get('/int/int:id', '')
    ..get('/double/double:id', '')
    ..get('/num/num:id', '');

  num getId(String path) {
    var result = router.resolveAbsolute(path).first;
    return result.allParams['id'];
  }

  test('parse', () {
    expect(getId('/int/2'), 2);
    expect(getId('/double/2.0'), 2.0);
    expect(getId('/num/-2.4'), -2.4);
  });
}
