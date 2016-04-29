import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart';
import 'package:test/test.dart';

main() {
  group('routing', () {
    Angel angel;
    Angel nested;
    Angel todos;
    String url;
    http.Client client;
    God god;

    setUp(() async {
      god = new God();
      angel = new Angel();
      nested = new Angel();
      todos = new Angel();

      angel.registerMiddleware('interceptor', (req, res) async {
        res.write('Middleware');
        return false;
      });

      todos.get('/action/:action', (req, res) => res.json(req.params));
      nested.post('/ted/:route', (req, res) => res.json(req.params));
      angel.get('/intercepted', 'This should not be shown',
          middleware: ['interceptor']);
      angel.get('/hello', 'world');
      angel.get('/name/:first/last/:last', (req, res) => req.params);
      angel.post('/lambda', (req, res) => req.body);
      angel.use('/nes', nested);
      angel.use('/todos/:id', todos);
      angel.get('*', 'MJ');

      client = new http.Client();
      await angel.startServer(InternetAddress.LOOPBACK_IP_V4, 0);
      url = "http://${angel.httpServer.address.host}:${angel.httpServer.port}";
    });

    tearDown(() async {
      await angel.httpServer.close(force: true);
      angel = null;
      nested = null;
      todos = null;
      client.close();
      client = null;
      url = null;
      god = null;
    });

    test('Can match basic url', () async {
      var response = await client.get("$url/hello");
      expect(response.body, equals('"world"'));
    });

    test('Can match url with multiple parameters', () async {
      var response = await client.get('$url/name/HELLO/last/WORLD');
      var json = god.deserialize(response.body);
      expect(json['first'], equals('HELLO'));
      expect(json['last'], equals('WORLD'));
    });

    test('Can nest another Angel instance', () async {
      var response = await client.post('$url/nes/ted/foo');
      var json = god.deserialize(response.body);
      expect(json['route'], equals('foo'));
    });

    test('Can parse parameters from a nested Angel instance', () async {
      var response = await client.get('$url/todos/1337/action/test');
      var json = god.deserialize(response.body);
      expect(json['id'], equals(1337));
      expect(json['action'], equals('test'));
    });

    test('Can add and use named middleware', () async {
      var response = await client.get('$url/intercepted');
      expect(response.body, equals('Middleware'));
    });

    test('Can serialize function result as JSON', () async {
      Map headers = {'Content-Type': 'application/json'};
      String postData = god.serialize({'it': 'works'});
      var response = await client.post(
          "$url/lambda", headers: headers, body: postData);
      expect(god.deserialize(response.body)['it'], equals('works'));
    });

    test('Fallback routes', () async {
      var response = await client.get('$url/my_favorite_artist');
      expect(response.body, equals('"MJ"'));
    });
  });
}