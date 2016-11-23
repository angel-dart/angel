import 'package:test/test.dart';
import 'route/all_test.dart' as route;
import 'router/all_test.dart' as router;

main() {
  group('route', route.main);
  group('router', router.main);
}