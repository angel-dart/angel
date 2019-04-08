import 'dart:convert';
import 'dart:io';

import 'package:angel_container/angel_container.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:http/http.dart' as http;
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

import 'common.dart';

final String TEXT = "make your bed";
final String OVER = "never";

main() {
  Angel app;
  http.Client client;
  HttpServer server;
  String url;

  setUp(() async {
    app = new Angel(reflector: MirrorsReflector());
    client = new http.Client();

    // Inject some todos
    app.container.registerSingleton(new Todo(text: TEXT, over: OVER));

    app.get("/errands", ioc((Todo singleton) => singleton));
    app.get(
        "/errands3",
        ioc(({Errand singleton, Todo foo, RequestContext req}) =>
            singleton.text));
    await app.configure(new SingletonController().configureServer);
    await app.configure(new ErrandController().configureServer);

    server = await new AngelHttp(app).startServer();
    url = "http://${server.address.host}:${server.port}";
  });

  tearDown(() async {
    app = null;
    url = null;
    client.close();
    client = null;
    await server.close(force: true);
  });

  test('runContained with custom container', () async {
    var app = new Angel();
    var c = new Container(const MirrorsReflector());
    c.registerSingleton(new Todo(text: 'Hey!'));

    app.get('/', (req, res) async {
      return app.runContained((Todo t) => t.text, req, res, c);
    });

    var rq = new MockHttpRequest('GET', new Uri(path: '/'))..close();
    var rs = rq.response;
    await new AngelHttp(app).handleRequest(rq);
    var text = await rs.transform(utf8.decoder).join();
    expect(text, json.encode('Hey!'));
  });

  test("singleton in route", () async {
    validateTodoSingleton(await client.get("$url/errands"));
  });

  test("singleton in controller", () async {
    validateTodoSingleton(await client.get("$url/errands2"));
  });

  test("make in route", () async {
    var response = await client.get("$url/errands3");
    var text = await json.decode(response.body) as String;
    expect(text, equals(TEXT));
  });

  test("make in controller", () async {
    var response = await client.get("$url/errands4");
    var text = await json.decode(response.body) as String;
    expect(text, equals(TEXT));
  });
}

void validateTodoSingleton(response) {
  var todo = json.decode(response.body.toString()) as Map;
  expect(todo["id"], equals(null));
  expect(todo["text"], equals(TEXT));
  expect(todo["over"], equals(OVER));
}

@Expose("/errands2")
class SingletonController extends Controller {
  @Expose("/")
  todo(Todo singleton) => singleton;
}

@Expose("/errands4")
class ErrandController extends Controller {
  @Expose("/")
  errand(Errand errand) {
    return errand.text;
  }
}

class Errand {
  Todo todo;

  String get text => todo.text;

  Errand(this.todo);
}
