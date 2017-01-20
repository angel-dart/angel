@TestOn('browser')
import 'package:angel_client/browser.dart';
import 'package:test/test.dart';
import 'for_browser_tests.dart';

main() {
  test("list todos", () async {
    var channel = spawnHybridCode(SERVER);
    int port = await channel.stream.first;
    var url = "http://localhost:$port";
    print(url);
    var app = new Rest(url);
    var todoService = app.service("todos");

    var todos = await todoService.index();
    expect(todos, isEmpty);
  });

  test('create todos', () async {
    var channel = spawnHybridCode(SERVER);
    int port = await channel.stream.first;
    var url = "http://localhost:$port";
    print(url);
    var app = new Rest(url);
    var todoService = app.service("todos");

    var data = {'hello': 'world'};
    var response = await todoService.create(data);
    print('Created response: $response');

    var todos = await todoService.index();
    expect(todos, hasLength(1));

    Map todo = todos.first;
    expect(todo, equals(data));
  });
}
