import 'dart:async';
import 'dart:io';
import 'package:angel_cache/angel_cache.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:http/http.dart' as http;
import 'package:glob/glob.dart';
import 'package:test/test.dart';

main() async {
  group('no timeout', () {
    TestClient client;
    DateTime lastModified;
    http.Response response1, response2;

    setUp(() async {
      var app = new Angel();
      var cache = new ResponseCache()
        ..patterns.addAll([
          new Glob('/*.txt'),
        ]);

      app.fallback(cache.handleRequest);

      app.get('/date.txt', (req, res) {
        res
          ..useBuffer()
          ..write(new DateTime.now().toIso8601String());
      });

      app.addRoute('PURGE', '*', (req, res) {
        cache.purge(req.uri.path);
        print('Purged ${req.uri.path}');
      });

      app.responseFinalizers.add(cache.responseFinalizer);

      var oldHandler = app.errorHandler;
      app.errorHandler = (e, req, res) {
        if (e.error == null) return oldHandler(e, req, res);
        return Zone.current.handleUncaughtError(e.error, e.stackTrace);
      };

      client = await connectTo(app);
      response1 = await client.get('/date.txt');
      response2 = await client.get('/date.txt');
      print(response2.headers);
      lastModified = HttpDate.parse(response2.headers['last-modified']);
      print('Response 1 status: ${response1.statusCode}');
      print('Response 2 status: ${response2.statusCode}');
      print('Response 1 body: ${response1.body}');
      print('Response 2 body: ${response2.body}');
      print('Response 1 headers: ${response1.headers}');
      print('Response 2 headers: ${response2.headers}');
    });

    tearDown(() => client.close());

    test('saves content', () async {
      expect(response1.body, response2.body);
    });

    test('saves headers', () async {
      response1.headers.forEach((k, v) {
        expect(response2.headers, containsPair(k, v));
      });
    });

    test('first response is normal', () {
      expect(response1.statusCode, 200);
    });

    test('sends last-modified', () {
      expect(response2.headers.keys, contains('last-modified'));
    });

    test('invalidate', () async {
      await client.sendUnstreamed('PURGE', '/date.txt', {});
      var response = await client.get('/date.txt');
      print('Response after invalidation: ${response.body}');
      expect(response.body, isNot(response1.body));
    });

    test('sends 304 on if-modified-since', () async {
      var headers = {
        'if-modified-since':
            HttpDate.format(lastModified.add(const Duration(days: 1)))
      };
      var response = await client.get('/date.txt', headers: headers);
      print('Sending headers: $headers');
      print('Response (${response.statusCode}): ${response.headers}');
      expect(response.statusCode, 304);
    });

    test('last-modified in the past', () async {
      var response = await client.get('/date.txt', headers: {
        'if-modified-since':
            HttpDate.format(lastModified.subtract(const Duration(days: 10)))
      });
      print('Response: ${response.body}');
      expect(response.statusCode, 200);
      expect(response.body, isNot(response1.body));
    });
  });

  group('with timeout', () {});
}
