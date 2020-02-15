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
  List<Todo> todos = [Todo(text: "Hello", over: "world")];

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

class NoExposeController extends Controller {
  String getIndex() => 'Hey!';

  int timesTwo(int n) => n * 2;

  String repeatName(String name, int times) {
    var b = StringBuffer();
    for (int i = 0; i < times; i++) {
      b.writeln(name);
    }
    return b.toString();
  }

  @Expose('/yellow', method: 'POST')
  String someColor() => 'yellow';

  @Expose.patch
  int three() => 333;

  @noExpose
  String hideThis() => 'Should not be exposed';
}

@Expose('/named', as: 'foo')
class NamedController extends Controller {
  @Expose('/optional/:arg?', allowNull: ['arg'])
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
  TodoController todoController;
  NoExposeController noExposeCtrl;
  HttpServer server;
  http.Client client = http.Client();
  String url;

  setUp(() async {
    app = Angel(reflector: MirrorsReflector());
    app.get(
        "/redirect",
        (req, res) async =>
            res.redirectToAction("TodoController@foo", {"foo": "world"}));

    // Register as a singleton, just for the purpose of this test
    if (!app.container.has<TodoController>()) {
      app.container.registerSingleton(todoController = TodoController());
    }

    // Using mountController<T>();
    await app.mountController<TodoController>();

    noExposeCtrl = await app.mountController<NoExposeController>();

    // Place controller in group. The applyRoutes() call, however, is async.
    // Until https://github.com/angel-dart/route/issues/28 is closed,
    // this will need to be done by manually mounting the router.
    var subRouter = Router<RequestHandler>();
    await todoController.applyRoutes(subRouter, app.container.reflector);
    app.mount('/ctrl_group', subRouter);

    print(app.controllers);
    app.dumpTree();

    server = await AngelHttp(app).startServer();
    url = 'http://${server.address.address}:${server.port}';
  });

  tearDown(() async {
    await server.close(force: true);
    app = null;
    url = null;
  });

  test('basic', () {
    expect(todoController.app, app);
  });

  test('create dynamic handler', () async {
    var app = Angel(reflector: MirrorsReflector());
    app.get(
        '/foo',
        ioc(({String bar}) {
          return 2;
        }, optional: ['bar']));
    var rq = MockHttpRequest('GET', Uri(path: 'foo'));
    await AngelHttp(app).handleRequest(rq);
    var body = await utf8.decoder.bind(rq.response).join();
    expect(json.decode(body), 2);
  });

  test('optional name', () async {
    var app = Angel(reflector: MirrorsReflector());
    await app.configure(NamedController().configureServer);
    expect(app.controllers['foo'], const IsInstanceOf<NamedController>());
  });

  test("middleware", () async {
    var rgx = RegExp("^Hello, world!");
    var response = await client.get("$url/todos/0");
    print('Response: ${response.body}');

    expect(rgx.firstMatch(response.body)?.start, equals(0));

    var todo = json.decode(response.body.replaceAll(rgx, "")) as Map;
    print("Todo: $todo");
    expect(todo['text'], equals("Hello"));
    expect(todo['over'], equals("world"));
  });

  test("controller in group", () async {
    var rgx = RegExp("^Hello, world!");
    var response = await client.get("$url/ctrl_group/todos/0");
    print('Response: ${response.body}');

    expect(rgx.firstMatch(response.body)?.start, equals(0));

    var todo = json.decode(response.body.replaceAll(rgx, "")) as Map;
    print("Todo: $todo");
    expect(todo['text'], equals("Hello"));
    expect(todo['over'], equals("world"));
  });

  test("named actions", () async {
    var response = await client.get("$url/redirect");
    print('Response: ${response.body}');
    expect(response.body, equals("Hello, \"world!\""));
  });

  group('optional expose', () {
    test('removes suffixes from controller names', () {
      expect(noExposeCtrl.mountPoint.path, 'no_expose');
    });

    test('mounts correct routes', () {
      print(noExposeCtrl.routeMappings.keys);
      expect(noExposeCtrl.routeMappings.keys.toList(),
          ['getIndex', 'timesTwo', 'repeatName', 'someColor', 'three']);
    });

    test('mounts correct methods', () {
      void expectMethod(String name, String method) {
        expect(noExposeCtrl.routeMappings[name].method, method);
      }

      expectMethod('getIndex', 'GET');
      expectMethod('timesTwo', 'GET');
      expectMethod('repeatName', 'GET');
      expectMethod('someColor', 'POST');
      expectMethod('three', 'PATCH');
    });

    test('mounts correct paths', () {
      void expectPath(String name, String path) {
        expect(noExposeCtrl.routeMappings[name].path, path);
      }

      expectPath('getIndex', '/');
      expectPath('timesTwo', '/times_two/int:n');
      expectPath('repeatName', '/repeat_name/:name/int:times');
      expectPath('someColor', '/yellow');
      expectPath('three', '/three');
    });
  });
}
