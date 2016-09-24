import 'package:test/test.dart';

import 'server.dart' as server;
import 'uploads.dart' as uploads;

main() {
  group('server', server.main);
  group('uploads', uploads.main);
}
