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

    group('JSON', () {
      test('Post Simple JSON', () async {
        var response = await client.post(url, body: {
          'hello': 'world'
        });
        expect(response.body, equals('{"body":{"hello":"world"},"query":{}}'));
      });

      test('Post Complex JSON', () async {
        var postData = god.serialize({
          'hello': 'world',
          'nums': [1, 2.0, 3 - 1],
          'map': {
            'foo': {
              'bar': 'baz'
            }
          }
        });
        var response = await client.post(url, body: postData);
        var body = god.deserialize(response.body)['body'];
        expect(body['hello'], equals('world'));
      });
    });
  });
}