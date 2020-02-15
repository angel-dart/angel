import 'package:angel_framework/angel_framework.dart';
import 'package:test/test.dart';

main() {
  test('default view generator', () async {
    var app = Angel();
    var view = await app.viewGenerator('foo', {'bar': 'baz'});
    expect(view, contains('No view engine'));
  });
}
