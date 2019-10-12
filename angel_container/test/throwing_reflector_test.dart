import 'package:angel_container/angel_container.dart';
import 'package:test/test.dart';

void main() {
  var reflector = const ThrowingReflector();

  test('getName', () {
    expect(reflector.getName(#foo), 'foo');
    expect(reflector.getName(#==), '==');
  });

  test('reflectClass fails', () {
    expect(() => reflector.reflectClass(Truck), throwsUnsupportedError);
  });

  test('reflectType fails', () {
    expect(() => reflector.reflectType(Truck), throwsUnsupportedError);
  });

  test('reflectFunction throws', () {
    void doIt(int x) {}
    expect(() => reflector.reflectFunction(doIt), throwsUnsupportedError);
  });

  test('reflectInstance throws', () {
    expect(() => reflector.reflectInstance(Truck()), throwsUnsupportedError);
  });
}

class Truck {
  int get wheelCount => 4;

  void drive() {
    print('Vroom!!!');
  }
}
