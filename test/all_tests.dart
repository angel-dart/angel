import '../lib/angel_route.dart';

main() {
  final foo = new Route('/foo');
  final bar = foo.child('/bar');
  print(foo.path);
  print(bar.path);
}