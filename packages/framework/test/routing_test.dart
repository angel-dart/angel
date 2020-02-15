import 'dart:convert';
import 'dart:io';

import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:http/http.dart' as http;
import 'package:io/ansi.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'common.dart';

@Middleware([interceptor])
testMiddlewareMetadata(RequestContext req, ResponseContext res) async {
  return "This should not be shown.";
}

@Middleware([interceptService])
class QueryService extends Service {
  @override
  @Middleware([interceptor])
  read(id, [Map params]) async => params;
}

void interceptor(RequestContext req, ResponseContext res) {
  res
    ..write('Middleware')
    ..close();
}

bool interceptService(RequestContext req, ResponseContext res) {
  res.write("Service with ");
  return true;
}

main() {
  Angel app;
  Angel nested;
  Angel todos;
  String url;
  http.Client client;

  setUp(() async {
    app = Angel(reflector: MirrorsReflector());
    nested = Angel(reflector: MirrorsReflector());
    todos = Angel(reflector: MirrorsReflector());

    [app, nested, todos].forEach((Angel app) {
      app.logger = Logger('routing_test')
        ..onRecord.listen((rec) {
          if (rec.error != null) {
            stdout
              ..writeln(cyan.wrap(rec.toString()))
              ..writeln(cyan.wrap(rec.error.toString()))
              ..writeln(cyan.wrap(rec.stackTrace.toString()));
          }
        });
    });

    todos.get('/action/:action', (req, res) => res.json(req.params));

    Route ted;

    ted = nested.post('/ted/:route', (RequestContext req, res) {
      print('Params: ${req.params}');
      print('Path: ${ted.path}, uri: ${req.path}');
      print('matcher: ${ted.parser}');
      return req.params;
    });

    app.mount('/nes', nested);
    app.get('/meta', testMiddlewareMetadata);
    app.get('/intercepted', (req, res) => 'This should not be shown',
        middleware: [interceptor]);
    app.get('/hello', (req, res) => 'world');
    app.get('/name/:first/last/:last', (req, res) => req.params);
    app.post(
        '/lambda',
        (RequestContext req, res) =>
            req.parseBody().then((_) => req.bodyAsMap));
    app.mount('/todos/:id', todos);
    app
        .get('/greet/:name',
            (RequestContext req, res) async => "Hello ${req.params['name']}")
        .name = 'Named routes';
    app.get('/named', (req, ResponseContext res) async {
      await res.redirectTo('Named routes', {'name': 'tests'});
    });
    app.get('/log', (RequestContext req, res) async {
      print("Query: ${req.queryParameters}");
      return "Logged";
    });

    app.get('/method', (req, res) => 'Only GET');
    app.post('/method', (req, res) => 'Only POST');

    app.use('/query', QueryService());

    RequestHandler write(String message) {
      return (req, res) {
        res.write(message);
        return true;
      };
    }

    app.chain([write('a')]).chain([write('b'), write('c')]).get(
        '/chained', (req, res) => res.close());

    app.fallback((req, res) => 'MJ');

    //app.dumpTree(header: "DUMPING ROUTES:", showMatchers: true);

    client = http.Client();
    var server = await AngelHttp(app).startServer('127.0.0.1', 0);
    url = "http://${server.address.host}:${server.port}";
  });

  tearDown(() async {
    await app.close();
    app = null;
    nested = null;
    todos = null;
    client.close();
    client = null;
    url = null;
  });

  test('Can match basic url', () async {
    var response = await client.get("$url/hello");
    expect(response.body, equals('"world"'));
  });

  test('Can match url with multiple parameters', () async {
    var response = await client.get('$url/name/HELLO/last/WORLD');
    print('Response: ${response.body}');
    var json_ = json.decode(response.body);
    expect(json_, const IsInstanceOf<Map>());
    expect(json_['first'], equals('HELLO'));
    expect(json_['last'], equals('WORLD'));
  });

  test('Chained routes', () async {
    var response = await client.get("$url/chained");
    expect(response.body, equals('abc'));
  });

  test('Can nest another Angel instance', () async {
    var response = await client.post('$url/nes/ted/foo');
    var json_ = json.decode(response.body);
    expect(json_['route'], equals('foo'));
  });

  test('Can parse parameters from a nested Angel instance', () async {
    var response = await client.get('$url/todos/1337/action/test');
    var json_ = json.decode(response.body);
    print('JSON: $json_');
    expect(json_['id'], equals('1337'));
    expect(json_['action'], equals('test'));
  });

  test('Can add and use named middleware', () async {
    var response = await client.get('$url/intercepted');
    expect(response.body, equals('Middleware'));
  });

  test('Middleware via metadata', () async {
    // Metadata
    var response = await client.get('$url/meta');
    expect(response.body, equals('Middleware'));
  });

  test('Can serialize function result as JSON', () async {
    Map headers = <String, String>{'Content-Type': 'application/json'};
    String postData = json.encode({'it': 'works'});
    var response = await client.post("$url/lambda",
        headers: headers as Map<String, String>, body: postData);
    print('Response: ${response.body}');
    expect(json.decode(response.body)['it'], equals('works'));
  });

  test('Fallback routes', () async {
    var response = await client.get('$url/my_favorite_artist');
    expect(response.body, equals('"MJ"'));
  });

  test('Can name routes', () {
    Route foo = app.get('/framework/:id', null)..name = 'frm';
    print('Foo: $foo');
    String uri = foo.makeUri({'id': 'angel'});
    print(uri);
    expect(uri, equals('framework/angel'));
  });

  test('Redirect to named routes', () async {
    var response = await client.get('$url/named');
    print(response.body);
    expect(json.decode(response.body), equals('Hello tests'));
  });

  test('Match routes, even with query params', () async {
    var response =
        await client.get("$url/log?foo=bar&bar=baz&baz.foo=bar&baz.bar=foo");
    print(response.body);
    expect(json.decode(response.body), equals('Logged'));

    response = await client.get("$url/query/foo?bar=baz");
    print(response.body);
    expect(response.body, equals("Service with Middleware"));
  });

  test('only match route with matching method', () async {
    var response = await client.get("$url/method");
    print(response.body);
    expect(response.body, '"Only GET"');

    response = await client.post("$url/method");
    print(response.body);
    expect(response.body, '"Only POST"');

    response = await client.patch("$url/method");
    print(response.body);
    expect(response.body, '"MJ"');
  });
}
