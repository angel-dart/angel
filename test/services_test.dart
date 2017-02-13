import 'package:angel_framework/src/defs.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart' as god;
import 'package:test/test.dart';

class Todo extends Model {
  String text;
  String over;
}

main() {
  Map headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  };
  Angel app;
  String url;
  http.Client client;

  setUp(() async {
    app = new Angel();
    client = new http.Client();
    Service todos = new MemoryService<Todo>();
    app.use('/todos', todos);
    print(app.service("todos"));
    await app.startServer(null, 0);
    url = "http://${app.httpServer.address.host}:${app.httpServer.port}";
  });

  tearDown(() async {
    app = null;
    url = null;
    client.close();
    client = null;
  });

  group('memory', () {
    test('can index an empty service', () async {
      var response = await client.get("$url/todos/");
      print(response.body);
      expect(response.body, equals('[]'));
      for (int i = 0; i < 3; i++) {
        String postData = god.serialize({'text': 'Hello, world!'});
        await client.post(
            "$url/todos", headers: headers, body: postData);
      }
      response = await client.get("$url/todos");
      print(response.body);
      expect(god
          .deserialize(response.body)
          .length, equals(3));
    });

    test('can create data', () async {
      String postData = god.serialize({'text': 'Hello, world!'});
      var response = await client.post(
          "$url/todos", headers: headers, body: postData);
      var json = god.deserialize(response.body);
      print(json);
      expect(json['text'], equals('Hello, world!'));
    });

    test('can fetch data', () async {
      String postData = god.serialize({'text': 'Hello, world!'});
      await client.post(
          "$url/todos", headers: headers, body: postData);
      var response = await client.get(
          "$url/todos/0");
      var json = god.deserialize(response.body);
      print(json);
      expect(json['text'], equals('Hello, world!'));
    });

    test('can modify data', () async {
      String postData = god.serialize({'text': 'Hello, world!'});
      await client.post(
          "$url/todos", headers: headers, body: postData);
      postData = god.serialize({'text': 'modified'});
      var response = await client.patch(
          "$url/todos/0", headers: headers, body: postData);
      var json = god.deserialize(response.body);
      print(json);
      expect(json['text'], equals('modified'));
    });

    test('can overwrite data', () async {
      String postData = god.serialize({'text': 'Hello, world!'});
      await client.post(
          "$url/todos", headers: headers, body: postData);
      postData = god.serialize({'over': 'write'});
      var response = await client.post(
          "$url/todos/0", headers: headers, body: postData);
      var json = god.deserialize(response.body);
      print(json);
      expect(json['text'], equals(null));
      expect(json['over'], equals('write'));
    });

    test('can delete data', () async {
      String postData = god.serialize({'text': 'Hello, world!'});
      await client.post(
          "$url/todos", headers: headers, body: postData);
      var response = await client.delete(
          "$url/todos/0");
      var json = god.deserialize(response.body);
      print(json);
      expect(json['text'], equals('Hello, world!'));
      response = await client.get("$url/todos");
      print(response.body);
      expect(god
          .deserialize(response.body)
          .length, equals(0));
    });
  });
}