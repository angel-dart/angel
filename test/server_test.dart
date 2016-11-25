import 'dart:convert';
import 'dart:io';
import 'package:angel_route/angel_route.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

main() {
  http.Client client;
  final people = [
    {'name': 'John Smith'}
  ];
  final Router router = new Router(debug: true);
  HttpServer server;
  String url;

  router.get('/', (req, res) {
    res.write('Root');
    return false;
  });

  router.get('/hello', (req, res) {
    res.write('World');
    return false;
  });

  router.group('/people', (router) {
    router.get('/', (req, res) {
      res.write(JSON.encode(people));
      return false;
    });

    router.group('/:id', (router) {
      router.get('/', (req, res) {
        // In a real application, we would take the param,
        // but not here...
        res.write(JSON.encode(people.first));
        return false;
      });

      router.get('/name', (req, res) {
        // In a real application, we would take the param,
        // but not here...
        res.write(JSON.encode(people.first['name']));
        return false;
      });
    });
  });

  setUp(() async {
    client = new http.Client();

    router.dumpTree();
    server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 0);
    url = 'http://${server.address.address}:${server.port}';

    server.listen((req) async {
      final res = req.response;

      // Easy middleware pipeline
      final results = router.resolveAll(req.uri.toString(), req.uri.toString(),
          method: req.method);
      final pipeline = new MiddlewarePipeline(results);

      if (pipeline.handlers.isEmpty) {
        res
          ..statusCode = HttpStatus.NOT_FOUND
          ..writeln('404 Not Found');
      } else {
        for (final handler in pipeline.handlers) {
          if (!await handler(req, res)) break;
        }
      }

      await res.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    client.close();
    client = null;
    url = null;
  });

  group('top-level', () {
    group('get', () {
      test('root', () async {
        final res = await client.get(url);
        print('Response: ${res.body}');
        expect(res.body, equals('Root'));
      });

      test('path', () async {
        final res = await client.get('$url/hello');
        print('Response: ${res.body}');
        expect(res.body, equals('World'));
      });
    });
  });

  group('group', () {
    group('top-level', () {
      test('root', () async {
        final res = await client.get('$url/people');
        print('Response: ${res.body}');
        expect(JSON.decode(res.body), equals(people));
      });

      group('param', () {
        test('root', () async {
          final res = await client.get('$url/people/0');
          print('Response: ${res.body}');
          expect(JSON.decode(res.body), equals(people.first));
        });

        test('path', () async {
          final res = await client.get('$url/people/0/name');
          print('Response: ${res.body}');
          expect(JSON.decode(res.body), equals(people.first['name']));
        });
      });
    });
  });

  group('use', () {});
}
