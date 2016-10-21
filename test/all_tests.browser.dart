import 'package:test/test.dart';
import 'route/all_tests.dart' as route;
import 'router/all_tests.dart' as router;

main() {
  group('route', route.main);
  group('router', router.main);
}