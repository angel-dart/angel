import 'package:angel_framework/angel_framework.dart';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart';
import 'package:test/test.dart';

class Todo {
  int id;
  String text;
}

main() {
  group('Utilities', () {
    Map headers = {
      'Content-Type': 'application/json'
    };
    Angel angel;
    String url;
    http.Client client;
    God god;

    setUp(() async {
      angel = new Angel();
      client = new http.Client();
      god = new God();
      angel.use('/todos', new MemoryService<Todo>());
      await angel.startServer(null, 0);
      url = "http://${angel.httpServer.address.host}:${angel.httpServer.port}";
    });

    tearDown(() async {
      angel = null;
      url = null;
      client.close();
      client = null;
      god = null;
    });

    group('memory', () {
      test('can index an empty service', () async {
        var response = await client.get("$url/todos/");
        expect(response.body, equals('[]'));
      });

      test('can create data', () async {
        String postData = god.serialize({'text': 'Hello, world!'});
        var response = await client.post(
            "$url/todos/", headers: headers, body: postData);
        var json = god.deserialize(response.body);
        print(json);
        expect(json['text'], equals('Hello, world!'));
      });
    });
  });
}