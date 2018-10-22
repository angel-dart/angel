import 'package:angel_container/angel_container.dart';
import 'package:test/test.dart';

void main() {
  test('returns the same instance', () {
    var container = new Container(const EmptyReflector())
      ..registerLazySingleton<Dummy>((_) => new Dummy('a'));

    var first = container.make<Dummy>();
    expect(container.make<Dummy>(), first);
  });
}

class Dummy {
  final String s;

  Dummy(this.s);
}
