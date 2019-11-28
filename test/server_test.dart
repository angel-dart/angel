import 'dart:convert';
import 'dart:io';
import 'package:angel_route/angel_route.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const List<Map<String, String>> people = [
  {'name': 'John Smith'}
];

main() {
  http.Client client;

  final Router router = Router();
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
      res.write(json.encode(people));
      return false;
    });

    router.group('/:id', (router) {
      router.get('/', (req, res) {
        // In a real application, we would take the param,
        // but not here...
        res.write(json.encode(people.first));
        return false;
      });

      router.get('/name', (req, res) {
        // In a real application, we would take the param,
        // but not here...
        res.write(json.encode(people.first['name']));
        return false;
      });
    });
  });

  final beatles = Router();

  beatles.post('/spinal_clacker', (req, res) {
    res.write('come ');
    return true;
  });

  final yellow = Router()
    ..get('/submarine', (req, res) {
      res.write('we all live in a');
      return false;
    });

  beatles.group('/big', (router) {
    router.mount('/yellow', yellow);
  });

  beatles.all('*', (req, res) {
    res.write('together');
    return false;
  });

  router.mount('/beatles', beatles);

  setUp(() async {
    client = http.Client();

    router.dumpTree();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    url = 'http://${server.address.address}:${server.port}';

    server.listen((req) async {
      final res = req.response;

      // Easy middleware pipeline
      final results =
          router.resolveAbsolute(req.uri.toString(), method: req.method);
      final pipeline = MiddlewarePipeline(results);

      if (pipeline.handlers.isEmpty) {
        res
          ..statusCode = 404
          ..writeln('404 Not Found');
      } else {
        for (final handler in pipeline.handlers) {
          if (!((await handler(req, res)) as bool)) break;
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
        expect(json.decode(res.body), equals(people));
      });

      group('param', () {
        test('root', () async {
          final res = await client.get('$url/people/0');
          print('Response: ${res.body}');
          expect(json.decode(res.body), equals(people.first));
        });

        test('path', () async {
          final res = await client.get('$url/people/0/name');
          print('Response: ${res.body}');
          expect(json.decode(res.body), equals(people.first['name']));
        });
      });
    });
  });

  group('mount', () {
    group('path', () {
      test('top-level', () async {
        final res = await client.post('$url/beatles/spinal_clacker');
        print('Response: ${res.body}');
        expect(res.body, equals('come together'));
      });

      test('fallback', () async {
        final res = await client.patch('$url/beatles/muddy_water');
        print('Response: ${res.body}');
        expect(res.body, equals('together'));
      });

      test('fallback', () async {
        final res = await client.patch('$url/beatles/spanil_clakcer');
        print('Response: ${res.body}');
        expect(res.body, equals('together'));
      });
    });

    test('deep nested', () async {
      final res = await client.get('$url/beatles/big/yellow/submarine');
      print('Response: ${res.body}');
      expect(res.body, equals('we all live in a'));
    });

    group('fallback', () {});
  });

  group('404', () {
    expect404(r) => r.then((res) {
          print('Response (${res.statusCode}): ${res.body}');
          expect(res.statusCode, equals(404));
        });

    test('path', () async {
      await expect404(client.get('$url/foo'));
      await expect404(client.get('$url/bye'));
      await expect404(client.get('$url/people/0/age'));
      await expect404(client.get('$url/beatles2'));
    });

    test('method', () async {
      await expect404(client.head(url));
      await expect404(client.patch('$url/people'));
      await expect404(client.post('$url/people/0'));
      await expect404(client.delete('$url/beatles2/spinal_clacker'));
    });
  });
}
