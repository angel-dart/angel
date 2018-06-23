import 'package:angel_framework/angel_framework.dart';
import 'package:dart2_constant/convert.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

@Middleware(const ['interceptor'])
testMiddlewareMetadata(RequestContext req, ResponseContext res) async {
  return "This should not be shown.";
}

@Middleware(const ['intercept_service'])
class QueryService extends Service {
  @override
  @Middleware(const ['interceptor'])
  read(id, [Map params]) async => params;
}

main() {
  Angel app;
  Angel nested;
  Angel todos;
  String url;
  http.Client client;

  setUp(() async {
    app = new Angel();
    nested = new Angel();
    todos = new Angel();

    // Lazy-parse in production
    [app, nested, todos].forEach((Angel app) {
      app.lazyParseBodies = app.isProduction;
    });

    app.requestMiddleware
      ..['interceptor'] = (req, res) async {
        res.write('Middleware');
        return false;
      }
      ..['intercept_service'] = (RequestContext req, res) async {
        res.write("Service with ");
        return true;
      };

    todos.get('/action/:action', (req, res) => res.json(req.params));

    Route ted;

    ted = nested.post('/ted/:route', (RequestContext req, res) {
      print('Params: ${req.params}');
      print('Path: ${ted.path}, uri: ${req.path}');
      print('matcher: ${ted.parser}');
      return req.params;
    });

    app.use('/nes', nested);
    app.get('/meta', testMiddlewareMetadata);
    app.get('/intercepted', 'This should not be shown',
        middleware: ['interceptor']);
    app.get('/hello', 'world');
    app.get('/name/:first/last/:last', (req, res) => req.params);
    app.post('/lambda', (RequestContext req, res) => req.lazyBody());
    app.use('/todos/:id', todos);
    app
        .get('/greet/:name',
            (RequestContext req, res) async => "Hello ${req.params['name']}")
        .name = 'Named routes';
    app.get('/named', (req, ResponseContext res) async {
      res.redirectTo('Named routes', {'name': 'tests'});
    });
    app.get('/log', (RequestContext req, res) async {
      print("Query: ${req.query}");
      return "Logged";
    });

    app.get('/method', () => 'Only GET');
    app.post('/method', () => 'Only POST');

    app.use('/query', new QueryService());

    RequestMiddleware write(String message) {
      return (req, res) async {
        res.write(message);
        return true;
      };
    }

    app
        .chain(write('a'))
        .chain([write('b'), write('c')]).get('/chained', () => false);

    app.use('MJ');

    app.dumpTree(header: "DUMPING ROUTES:", showMatchers: true);

    client = new http.Client();
    var server = await new AngelHttp(app).startServer('127.0.0.1', 0);
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
    expect(json_, const TypeMatcher<Map>());
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
    Map headers = {'Content-Type': 'application/json'};
    String postData = json.encode({'it': 'works'});
    var response = await client.post("$url/lambda",
        headers: headers.cast<String, String>(), body: postData);
    print('Response: ${response.body}');
    expect(json.decode(response.body)['it'], equals('works'));
  });

  test('Fallback routes', () async {
    var response = await client.get('$url/my_favorite_artist');
    expect(response.body, equals('"MJ"'));
  });

  test('Can name routes', () {
    Route foo = app.get('/framework/:id', [])..name = 'frm';
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
