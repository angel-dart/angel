import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

void main() {
  test('uri params decoded', () {
    var router = Router()..get('/a/:a/b/:b', '');

    var encoded =
        '/a/' + Uri.encodeComponent('<<<') + '/b/' + Uri.encodeComponent('???');
    print(encoded);
    var result = router.resolveAbsolute(encoded).first;
    print(result.allParams);
    expect(result.allParams, {
      'a': '<<<',
      'b': '???',
    });
  });
}
