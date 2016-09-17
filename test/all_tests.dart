import 'package:test/test.dart';
import 'controller.dart' as controller;
import 'di.dart' as di;
import 'hooked.dart' as hooked;
import 'routing.dart' as routing;
import 'services.dart' as services;

main() {
  group('controller', controller.main);
  group('hooked', hooked.main);
  group('di', di.main);
  group('routing', routing.main);
  group('services', services.main);
}