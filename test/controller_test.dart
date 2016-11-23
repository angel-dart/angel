import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'common.dart';

@Expose("/todos", middleware: const ["foo"])
class TodoController extends Controller {
  List<Todo> todos = [new Todo(text: "Hello", over: "world")];

  @Expose("/:id", middleware: const ["bar"])
  Future<Todo> fetchTodo(
      int id, RequestContext req, ResponseContext res) async {
    expect(req, isNotNull);
    expect(res, isNotNull);
    return todos[id];
  }

  @Expose("/namedRoute/:foo", as: "foo")
  Future<String> someRandomRoute(
      RequestContext req, ResponseContext res) async {
    return "${req.params['foo']}!";
  }
}

main() {
  Angel app;
  HttpServer server;
  InternetAddress host = InternetAddress.LOOPBACK_IP_V4;
  int port = 3000;
  http.Client client;
  String url = "http://${host.address}:$port";

  setUp(() async {
    app = new Angel();
    app.registerMiddleware("foo", (req, res) async => res.write("Hello, "));
    app.registerMiddleware("bar", (req, res) async => res.write("world!"));
    app.get(
        "/redirect",
        (req, ResponseContext res) async =>
            res.redirectToAction("TodoController@foo", {"foo": "world"}));
    await app.configure(new TodoController());

    print(app.controllers);
    app.dumpTree();

    server = await app.startServer(host, port);
    client = new http.Client();
  });

  tearDown(() async {
    await server.close(force: true);
    app = null;
    client.close();
    client = null;
  });

  test("middleware", () async {
    var rgx = new RegExp("^Hello, world!");
    var response = await client.get("$url/todos/0");
    print(response.body);

    expect(rgx.firstMatch(response.body).start, equals(0));

    Map todo = JSON.decode(response.body.replaceAll(rgx, ""));
    print("Todo: $todo");
    expect(todo.keys.length, equals(3));
    expect(todo['text'], equals("Hello"));
    expect(todo['over'], equals("world"));
  });

  test("named actions", () async {
    var response = await client.get("$url/redirect");
    print(response.body);

    expect(response.body, equals("Hello, \"world!\""));
  });
}
