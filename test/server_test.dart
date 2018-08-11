import 'dart:io' show HttpRequest, HttpServer;

import 'package:body_parser/body_parser.dart';
import 'package:dart2_constant/convert.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const TOKEN =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiIxMjcuMC4wLjEiLCJleHAiOi0xLCJpYXQiOiIyMDE2LTEyLTIyVDEyOjQ5OjUwLjM2MTQ0NiIsImlzcyI6ImFuZ2VsX2F1dGgiLCJzdWIiOiIxMDY2OTQ4Mzk2MDIwMjg5ODM2NTYifQ==.PYw7yUb-cFWD7N0sSLztP7eeRvO44nu1J2OgDNyT060=';

String jsonEncodeBody(BodyParseResult result) {
  return json.encode({
    'query': result.query,
    'body': result.body,
    'error': result.error?.toString(),
    'files': result.files.map((f) {
      return {
        'name': f.name,
        'mimeType': f.mimeType,
        'filename': f.filename,
        'data': f.data,
      };
    }).toList(),
    'originalBuffer': result.originalBuffer,
    'stack': null, //result.stack.toString(),
  });
}

main() {
  HttpServer server;
  String url;
  http.Client client;

  setUp(() async {
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((HttpRequest request) async {
      //Server will simply return a JSON representation of the parsed body
      request.response.write(
          // ignore: deprecated_member_use
          jsonEncodeBody(await parseBody(request, storeOriginalBuffer: true)));
      await request.response.close();
    });
    url = 'http://localhost:${server.port}';
    print('Test server listening on $url');
    client = new http.Client();
  });
  tearDown(() async {
    await server.close(force: true);
    client.close();
    server = null;
    url = null;
    client = null;
  });

  group('query string', () {
    test('GET Simple', () async {
      print('GET $url/?hello=world');
      var response = await client.get('$url/?hello=world');
      print('Response: ${response.body}');
      var result = json.decode(response.body);
      expect(result['body'], equals({}));
      expect(result['query'], equals({'hello': 'world'}));
      expect(result['files'], equals([]));
      //expect(result['originalBuffer'], isNull);
    });

    test('GET Complex', () async {
      var postData =
          'hello=world&nums%5B%5D=1&nums%5B%5D=2.0&nums%5B%5D=${3 - 1}&map.foo.bar=baz';
      print('Body: $postData');
      var response = await client.get('$url/?$postData');
      print('Response: ${response.body}');
      var query = json.decode(response.body)['query'];
      expect(query['hello'], equals('world'));
      expect(query['nums'][2], equals(2));
      expect(query['map'] is Map, equals(true));
      expect(query['map']['foo'], equals({'bar': 'baz'}));
    });

    test('JWT', () async {
      var postData = 'token=$TOKEN';
      print('Body: $postData');
      var response = await client.get('$url/?$postData');
      print('Response: ${response.body}');
      var query = json.decode(response.body)['query'];
      expect(query['token'], equals(TOKEN));
    });
  });

  group('urlencoded', () {
    Map<String, String> headers = {
      'content-type': 'application/x-www-form-urlencoded'
    };
    test('POST Simple', () async {
      print('Body: hello=world');
      var response =
          await client.post(url, headers: headers, body: 'hello=world');
      print('Response: ${response.body}');
      var result = json.decode(response.body);
      expect(result['query'], equals({}));
      expect(result['body'], equals({'hello': 'world'}));
      expect(result['files'], equals([]));
      expect(result['originalBuffer'], isList);
      expect(result['originalBuffer'], isNotEmpty);
    });

    test('Post Complex', () async {
      var postData =
          'hello=world&nums%5B%5D=1&nums%5B%5D=2.0&nums%5B%5D=${3 - 1}&map.foo.bar=baz';
      var response = await client.post(url, headers: headers, body: postData);
      print('Response: ${response.body}');
      var body = json.decode(response.body)['body'];
      expect(body['hello'], equals('world'));
      expect(body['nums'][2], equals(2));
      expect(body['map'] is Map, equals(true));
      expect(body['map']['foo'], equals({'bar': 'baz'}));
    });

    test('JWT', () async {
      var postData = 'token=$TOKEN';
      var response = await client.post(url, headers: headers, body: postData);
      var body = json.decode(response.body)['body'];
      expect(body['token'], equals(TOKEN));
    });
  });

  group('json', () {
    Map<String, String> headers = {'content-type': 'application/json'};
    test('Post Simple', () async {
      var postData = json.encode({'hello': 'world'});
      print('Body: $postData');
      var response = await client.post(url, headers: headers, body: postData);
      print('Response: ${response.body}');
      var result = json.decode(response.body);
      expect(result['body'], equals({'hello': 'world'}));
      expect(result['query'], equals({}));
      expect(result['files'], equals([]));
      expect(result['originalBuffer'], allOf(isList, isNotEmpty));
    });

    test('Post Complex', () async {
      var postData = json.encode({
        'hello': 'world',
        'nums': [1, 2.0, 3 - 1],
        'map': {
          'foo': {'bar': 'baz'}
        }
      });
      print('Body: $postData');
      var response = await client.post(url, headers: headers, body: postData);
      print('Response: ${response.body}');
      var body = json.decode(response.body)['body'];
      expect(body['hello'], equals('world'));
      expect(body['nums'][2], equals(2));
      expect(body['map'] is Map, equals(true));
      expect(body['map']['foo'], equals({'bar': 'baz'}));
    });
  });
}
