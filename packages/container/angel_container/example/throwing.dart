import 'package:angel_container/angel_container.dart';

void main() {
  var reflector = const ThrowingReflector();
  reflector.reflectClass(StringBuffer);
}
