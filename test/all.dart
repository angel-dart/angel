import 'accepts_test.dart' as accepts;
import 'anonymous_service_test.dart' as anonymous_service;
import 'controller_test.dart' as controller;
import 'di_test.dart' as di;
import 'encoders_buffer_test.dart' as encoders_buffer;
import 'exception_test.dart' as exception;
import 'general_test.dart' as general;
import 'hooked_test.dart' as hooked;
import 'parameter_meta_test.dart' as parameter_meta;
import 'precontained_test.dart' as precontained;
import 'primitives_test.dart' as primitives;
import 'repeat_request_test.dart' as repeat_request;
import 'routing_test.dart' as routing;
import 'serialize_test.dart' as serialize;
import 'server_test.dart' as server;
import 'services_test.dart' as services;
import 'streaming_test.dart' as streaming;
import 'typed_service_test.dart' as typed_service;
import 'view_generator_test.dart' as view_generator;
import 'package:test/test.dart';

/// For running with coverage
main() {
  group('accepts', accepts.main);
  group('anonymous service', anonymous_service.main);
  group('controller', controller.main);
  group('di', di.main);
  group('encoders_buffer', encoders_buffer.main);
  group('exception', exception.main);
  group('general', general.main);
  group('hooked', hooked.main);
  group('parameter_meta', parameter_meta.main);
  group('precontained', precontained.main);
  group('primitives', primitives.main);
  group('repeat request', repeat_request.main);
  group('routing', routing.main);
  group('serialize', serialize.main);
  group('server', server.main);
  group('services', services.main);
  group('streaming', streaming.main);
  group('typed_service', typed_service.main);
  group('view generator', view_generator.main);
}
