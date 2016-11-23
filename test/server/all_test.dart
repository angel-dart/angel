import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:angel_route/angel_route.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

typedef Future<bool> RequestHandler(HttpRequest request);

final String MIDDLEWARE_GREETING = 'Hi, I am a middleware!';

main() {
  http.Client client;
  Router router;
  HttpServer server;
  String url;

  setUp(() async {
    client = new http.Client();
    router = new Router(debug: true);
    server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 0);
    url = 'http://${server.address.address}:${server.port}';

    server.listen((request) async {
      final resolved = router.resolve(request.uri.path, method: request.method);

      if (resolved == null) {
        request.response.statusCode = 404;
        request.response.write('404 Not Found');
        await request.response.close();
      } else {
        // Easy middleware pipeline
        for (final handler in resolved.handlerSequence) {
          if (handler is String) {
            if (!await router.requestMiddleware[handler](request)) break;
          } else if (!await handler(request)) {
            break;
          }
        }

        await request.response.close();
      }
    });

    router.get('foo', (HttpRequest request) async {
      request.response.write('bar');
      return false;
    });

    Route square;

    square = router.post('square/:num([0-9]+)', (HttpRequest request) async {
      final params = square.parseParameters(request.uri.toString());
      final squared = math.pow(params['num'], 2);
      request.response.statusCode = squared;
      request.response.write(squared);
      return false;
    });

    router.group('todos', (router) {
      router.get('/', (HttpRequest request) async {
        print('TODO INDEX???');
        request.response.write([]);
        return false;
      });
    }, middleware: [
      (HttpRequest request) async {
        request.response.write(MIDDLEWARE_GREETING);
        return true;
      }
    ]);

    router.dumpTree();
  });

  tearDown(() async {
    client.close();
    client = null;
    router = null;
    url = null;
    await server.close();
  });

  group('group', () {
    test('todo index', () async {
      final response = await client.get('$url/todos');
      expect(response.statusCode, equals(200));
      expect(response.body, equals('$MIDDLEWARE_GREETING[]'));
    });
  });

  group('top-level route', () {
    test('no params', () async {
      final response = await client.get('$url/foo');
      expect(response.statusCode, equals(200));
      expect(response.body, equals('bar'));
    });

    test('with params', () async {
      final response = await client.post('$url/square/16');
      expect(response.statusCode, equals(256));
      expect(response.body, equals(response.statusCode.toString()));
    });

    test('throw 404', () async {
      final response = await client.get('$url/abc');
      expect(response.statusCode, equals(404));
    });
  });
}
