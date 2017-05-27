import 'controller_test.dart' as controller;
import 'di_test.dart' as di;
import 'general_test.dart' as general;
import 'hooked_test.dart' as hooked;
import 'routing_test.dart' as routing;
import 'serialize_test.dart' as serialize;
import 'services_test.dart' as services;
import 'util_test.dart' as util;
import 'package:test/test.dart';

/// For running with coverage
main() {
  group('controller', controller.main);
  group('di', di.main);
  group('general', general.main);
  group('hooked', hooked.main);
  group('routing', routing.main);
  group('serialize', serialize.main);
  group('services', services.main);
  group('util', util.main);
}