import 'package:test/test.dart';
import 'bounds_test.dart' as bounds;
import 'paginate_test.dart' as paginate;
import 'server_test.dart' as server;

main() {
  group('bounds', bounds.main);
  group('paginate', paginate.main);
  group('server', server.main);
}