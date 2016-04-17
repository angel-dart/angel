import 'dart:io';

import 'package:body_parser/body_parser.dart';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart';
import 'package:test/test.dart';

main() {
  group('Test server support', () {
    HttpServer server;
    String url;
    http.Client client;
    God god;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 0);
      server.listen((HttpRequest request) async {
        //Server will simply return a JSON representation of the parsed body
        request.response.write(god.serialize(await parseBody(request)));
        await request.response.close();
      });
      url = 'http://localhost:${server.port}';
      print('Test server listening on $url');
      client = new http.Client();
      god = new God();
    });
    tearDown(() async {
      await server.close(force: true);
      client.close();
      server = null;
      url = null;
      client = null;
      god = null;
    });

    group('query string', () {
      test('GET Simple', () async {
        print('GET $url/?hello=world');
        var response = await client.get('$url/?hello=world');
        print('Response: ${response.body}');
        expect(response.body, equals('{"body":{},"query":{"hello":"world"}}'));
      });

      test('GET Complex', () async {
        var postData = 'hello=world&nums%5B%5D=1&nums%5B%5D=2.0&nums%5B%5D=${3 -
            1}&map.foo.bar=baz';
        print('Body: $postData');
        var response = await client.get('$url/?$postData');
        print('Response: ${response.body}');
        var query = god.deserialize(response.body)['query'];
        expect(query['hello'], equals('world'));
        expect(query['nums'][2], equals(2));
        expect(query['map'] is Map, equals(true));
        expect(query['map']['foo'], equals({'bar': 'baz'}));
      });
    });

    group('urlencoded', () {
      Map<String, String> headers = {
        HttpHeaders.CONTENT_TYPE: 'application/x-www-form-urlencoded'
      };
      test('POST Simple', () async {
        print('Body: hello=world');
        var response = await client.post(
            url, headers: headers, body: 'hello=world');
        print('Response: ${response.body}');
        expect(response.body, equals('{"body":{"hello":"world"},"query":{}}'));
      });

      test('Post Complex', () async {
        var postData = 'hello=world&nums%5B%5D=1&nums%5B%5D=2.0&nums%5B%5D=${3 -
            1}&map.foo.bar=baz';
        var response = await client.post(url, headers: headers, body: postData);
        var body = god.deserialize(response.body)['body'];
        expect(body['hello'], equals('world'));
        expect(body['nums'][2], equals(2));
        expect(body['map'] is Map, equals(true));
        expect(body['map']['foo'], equals({'bar': 'baz'}));
      });
    });

    group('JSON', () {
      Map<String, String> headers = {
        HttpHeaders.CONTENT_TYPE: ContentType.JSON.toString()
      };
      test('Post Simple', () async {
        var postData = god.serialize({
          'hello': 'world'
        });
        print('Body: $postData');
        var response = await client.post(
            url, headers: headers, body: postData);
        print('Response: ${response.body}');
        expect(response.body, equals('{"body":{"hello":"world"},"query":{}}'));
      });

      test('Post Complex', () async {
        var postData = god.serialize({
          'hello': 'world',
          'nums': [1, 2.0, 3 - 1],
          'map': {
            'foo': {
              'bar': 'baz'
            }
          }
        });
        print('Body: $postData');
        var response = await client.post(url, headers: headers, body: postData);
        print('Response: ${response.body}');
        var body = god.deserialize(response.body)['body'];
        expect(body['hello'], equals('world'));
        expect(body['nums'][2], equals(2));
        expect(body['map'] is Map, equals(true));
        expect(body['map']['foo'], equals({'bar': 'baz'}));
      });
    });
  });
}