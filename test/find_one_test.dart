import 'package:angel_framework/angel_framework.dart';
import 'package:test/test.dart';
import 'common.dart';

void main() {
  var throwsAnAngelHttpException =
      throwsA(const IsInstanceOf<AngelHttpException>());

  test('throw 404 on null', () {
    var service = AnonymousService(index: ([p]) => null);
    expect(() => service.findOne(), throwsAnAngelHttpException);
  });

  test('throw 404 on empty iterable', () {
    var service = AnonymousService(index: ([p]) => []);
    expect(() => service.findOne(), throwsAnAngelHttpException);
  });

  test('return first element of iterable', () async {
    var service = AnonymousService(index: ([p]) => [2]);
    expect(await service.findOne(), 2);
  });
}
