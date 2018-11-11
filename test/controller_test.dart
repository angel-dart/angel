import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:http/http.dart' as http;
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

import 'common.dart';

@Expose("/todos", middleware: [foo])
class TodoController extends Controller {
  List<Todo> todos = [new Todo(text: "Hello", over: "world")];

  @Expose("/:id", middleware: [bar])
  Future<Todo> fetchTodo(
      String id, RequestContext req, ResponseContext res) async {
    expect(req, isNotNull);
    expect(res, isNotNull);
    return todos[int.parse(id)];
  }

  @Expose("/namedRoute/:foo", as: "foo")
  Future<String> someRandomRoute(
      RequestContext req, ResponseContext res) async {
    return "${req.params['foo']}!";
  }
}

class NoExposeController extends Controller {}

@Expose('/named', as: 'foo')
class NamedController extends Controller {
  @Expose('/optional/:arg?', allowNull: const ['arg'])
  optional() => 2;
}

bool foo(RequestContext req, ResponseContext res) {
  res.write("Hello, ");
  return true;
}

bool bar(RequestContext req, ResponseContext res) {
  res.write("world!");
  return true;
}

main() {
  Angel app;
  TodoController ctrl;
  HttpServer server;
  http.Client client = new http.Client();
  String url;

  setUp(() async {
    app = new Angel(reflector: MirrorsReflector());
    app.get(
        "/redirect",
        (req, res) async =>
            res.redirectToAction("TodoController@foo", {"foo": "world"}));

    // Register as a singleton, just for the purpose of this test
    if (!app.container.has<TodoController>())
      app.container.registerSingleton(ctrl = new TodoController());

    // Using mountController<T>();
    await app.mountController<TodoController>();

    print(app.controllers);
    app.dumpTree();

    server = await new AngelHttp(app).startServer();
    url = 'http://${server.address.address}:${server.port}';
  });

  tearDown(() async {
    await server.close(force: true);
    app = null;
    url = null;
  });

  test('basic', () {
    expect(ctrl.app, app);
  });

  test('require expose', () async {
    try {
      var app = new Angel(reflector: MirrorsReflector());
      await app.configure(new NoExposeController().configureServer);
      throw 'Should require @Expose';
    } on Exception {
      // :)
    }
  });

  test('create dynamic handler', () async {
    var app = new Angel(reflector: MirrorsReflector());
    app.get(
        '/foo',
        ioc(({String bar}) {
          return 2;
        }, optional: ['bar']));
    var rq = new MockHttpRequest('GET', new Uri(path: 'foo'));
    await new AngelHttp(app).handleRequest(rq);
    var body = await rq.response.transform(utf8.decoder).join();
    expect(json.decode(body), 2);
  });

  test('optional name', () async {
    var app = new Angel(reflector: MirrorsReflector());
    await app.configure(new NamedController().configureServer);
    expect(app.controllers['foo'], const IsInstanceOf<NamedController>());
  });

  test("middleware", () async {
    var rgx = new RegExp("^Hello, world!");
    var response = await client.get("$url/todos/0");
    print('Response: ${response.body}');

    expect(rgx.firstMatch(response.body)?.start, equals(0));

    Map todo = json.decode(response.body.replaceAll(rgx, ""));
    print("Todo: $todo");
    expect(todo['text'], equals("Hello"));
    expect(todo['over'], equals("world"));
  });

  test("named actions", () async {
    var response = await client.get("$url/redirect");
    print('Response: ${response.body}');
    expect(response.body, equals("Hello, \"world!\""));
  });
}
