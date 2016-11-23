import 'dart:io';
import 'package:angel_route/angel_route.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

main() {
  http.Client client;
  Router router;
  HttpServer server;
  String url;

  setUp(() async {
    client = new http.Client();
    router = new Router();
    server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 0);
    url = 'http://${server.address.address}:${server.port}';

    router.get('/hello', (req) {
      req.response.write('world');
    });

    router.get('/sandwich', (req) {
      req.response.write('pb');
      return true;
    });

    router.all('/sandwich', (req) {
      req.response.write('&j');
      return false;
    });

    router.all('/chain', (req) {
      req.response.write('PassTo');
      return true;
    });

    router.group('/group/:id', (router) {
      router.get('/fun', (req) {
        req.response.write(' and fun!');
        return false;
      }, middleware: [
        (req) {
          req.response.write(' is cool');
          return true;
        }
      ]);
    }, middleware: [
      (req) {
        req.response.write('Dart');
        return true;
      }
    ]);

    final beatles = new Router();

    beatles.get('/come-together', (req) {
      req.response.write('spinal');
      return true;
    });

    beatles.all('*', (req) {
      req.response.write('-clacker');
      return !req.uri.toString().contains('come-together');
    });

    router.mount('/beatles', beatles);

    router.all('*', (req) {
      req.response.write('Fallback');
      return false;
    });

    router
      ..normalize()
      ..dumpTree(showMatchers: true);

    server.listen((request) async {
      final resolved =
          router.resolveAll(request.uri.path, method: request.method);

      if (resolved.isEmpty) {
        request.response.statusCode = 404;
        request.response.write('404 Not Found');
        await request.response.close();
      } else {
        print('Resolved ${request.uri} => $resolved');

        // Easy middleware pipeline
        final pipeline = [];

        for (Route route in resolved) {
          pipeline.addAll(route.handlerSequence);
        }

        print('Pipeline: ${pipeline.length} handler(s)');

        for (final handler in pipeline) {
          if (handler(request) != true) break;
        }

        await request.response.close();
      }
    });
  });

  tearDown(() async {
    client.close();
    client = null;
    router = null;
    url = null;
    await server.close();
  });

  test('hello', () async {
    final response = await client.get('$url/hello');
    print('Response: ${response.body}');
    expect(response.body, equals('world'));
  });

  test('sandwich', () async {
    final response = await client.get('$url/sandwich');
    print('Response: ${response.body}');
    expect(response.body, equals('pb&j'));
  });

  test('chain', () async {
    final response = await client.get('$url/chain');
    print('Response: ${response.body}');
    expect(response.body, equals('PassToFallback'));
  });

  test('fallback', () async {
    final response = await client.get('$url/fallback');
    print('Response: ${response.body}');
    expect(response.body, equals('Fallback'));
  });

  group('group', () {
    test('fun', () async {
      final response = await client.get('$url/group/abc/fun');
      print('Response: ${response.body}');
      expect(response.body, equals('Dart is cool and fun!'));
    });

    test('fallback', () async {
      final response = await client.get('$url/group/abc');
      print('Response: ${response.body}');
      expect(response.body, equals('Fallback'));
    });
  });

  group('beatles', () {
    test('spinal clacker', () async {
      final response = await client.get('$url/beatles/come-together');
      print('Response: ${response.body}');
      expect(response.body, equals('spinal-clacker'));
    });

    group('fallback', () {
      setUp(() {
        router.linearClone().dumpTree(header: 'LINEAR', showMatchers: true);
      });

      test('non-existent', () async {
        var response = await client.get('$url/beatles/ringo-starr');
        print('Response: ${response.body}');
        expect(response.body, equals('-clackerFallback'));
      });

      test('root', () async {
        var response = await client.get('$url/beatles');
        print('Response: ${response.body}');
        expect(response.body, equals('Fallback'));
      });
    });
  });
}
