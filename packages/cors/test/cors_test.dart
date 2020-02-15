import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_cors/angel_cors.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

main() {
  Angel app;
  AngelHttp server;
  http.Client client;

  setUp(() async {
    app = Angel()
      ..options('/credentials', cors(CorsOptions(credentials: true)))
      ..options('/credentials_d',
          dynamicCors((req, res) => CorsOptions(credentials: true)))
      ..options(
          '/headers', cors(CorsOptions(exposedHeaders: ['x-foo', 'x-bar'])))
      ..options('/max_age', cors(CorsOptions(maxAge: 250)))
      ..options('/methods', cors(CorsOptions(methods: ['GET', 'POST'])))
      ..get(
          '/originl',
          chain([
            cors(CorsOptions(
              origin: ['foo.bar', 'baz.quux'],
            )),
            (req, res) => req.headers['origin']
          ]))
      ..get(
          '/origins',
          chain([
            cors(CorsOptions(
              origin: 'foo.bar',
            )),
            (req, res) => req.headers['origin']
          ]))
      ..get(
          '/originr',
          chain([
            cors(CorsOptions(
              origin: RegExp(r'^foo\.[^x]+$'),
            )),
            (req, res) => req.headers['origin']
          ]))
      ..get(
          '/originp',
          chain([
            cors(CorsOptions(
              origin: (String s) => s.endsWith('.bar'),
            )),
            (req, res) => req.headers['origin']
          ]))
      ..options('/status', cors(CorsOptions(successStatus: 418)))
      ..fallback(cors(CorsOptions()))
      ..post('/', (req, res) async {
        res.write('hello world');
      })
      ..fallback((req, res) => throw AngelHttpException.notFound());

    server = AngelHttp(app);
    await server.startServer('127.0.0.1', 0);
    client = http.Client();
  });

  tearDown(() async {
    await server.close();
    app = null;
    client = null;
  });

  test('status 204 by default', () async {
    var rq = http.Request('OPTIONS', server.uri.replace(path: '/max_age'));
    var response = await client.send(rq).then(http.Response.fromStream);
    expect(response.statusCode, 204);
  });

  test('content length 0 by default', () async {
    var rq = http.Request('OPTIONS', server.uri.replace(path: '/max_age'));
    var response = await client.send(rq).then(http.Response.fromStream);
    expect(response.contentLength, 0);
  });

  test('custom successStatus', () async {
    var rq = http.Request('OPTIONS', server.uri.replace(path: '/status'));
    var response = await client.send(rq).then(http.Response.fromStream);
    expect(response.statusCode, 418);
  });

  test('max age', () async {
    var rq = http.Request('OPTIONS', server.uri.replace(path: '/max_age'));
    var response = await client.send(rq).then(http.Response.fromStream);
    expect(response.headers['access-control-max-age'], '250');
  });

  test('methods', () async {
    var rq = http.Request('OPTIONS', server.uri.replace(path: '/methods'));
    var response = await client.send(rq).then(http.Response.fromStream);
    expect(response.headers['access-control-allow-methods'], 'GET,POST');
  });

  test('dynamicCors.credentials', () async {
    var rq =
        http.Request('OPTIONS', server.uri.replace(path: '/credentials_d'));
    var response = await client.send(rq).then(http.Response.fromStream);
    expect(response.headers['access-control-allow-credentials'], 'true');
  });

  test('credentials', () async {
    var rq = http.Request('OPTIONS', server.uri.replace(path: '/credentials'));
    var response = await client.send(rq).then(http.Response.fromStream);
    expect(response.headers['access-control-allow-credentials'], 'true');
  });

  test('exposed headers', () async {
    var rq = http.Request('OPTIONS', server.uri.replace(path: '/headers'));
    var response = await client.send(rq).then(http.Response.fromStream);
    expect(response.headers['access-control-expose-headers'], 'x-foo,x-bar');
  });

  test('invalid origin', () async {
    var response = await client.get(server.uri.replace(path: '/originl'),
        headers: {'origin': 'foreign'});
    expect(response.headers['access-control-allow-origin'], 'false');
  });

  test('list origin', () async {
    var response = await client.get(server.uri.replace(path: '/originl'),
        headers: {'origin': 'foo.bar'});
    expect(response.headers['access-control-allow-origin'], 'foo.bar');
    expect(response.headers['vary'], 'origin');
    response = await client.get(server.uri.replace(path: '/originl'),
        headers: {'origin': 'baz.quux'});
    expect(response.headers['access-control-allow-origin'], 'baz.quux');
    expect(response.headers['vary'], 'origin');
  });

  test('string origin', () async {
    var response = await client.get(server.uri.replace(path: '/origins'),
        headers: {'origin': 'foo.bar'});
    expect(response.headers['access-control-allow-origin'], 'foo.bar');
    expect(response.headers['vary'], 'origin');
  });

  test('regex origin', () async {
    var response = await client.get(server.uri.replace(path: '/originr'),
        headers: {'origin': 'foo.bar'});
    expect(response.headers['access-control-allow-origin'], 'foo.bar');
    expect(response.headers['vary'], 'origin');
  });

  test('predicate origin', () async {
    var response = await client.get(server.uri.replace(path: '/originp'),
        headers: {'origin': 'foo.bar'});
    expect(response.headers['access-control-allow-origin'], 'foo.bar');
    expect(response.headers['vary'], 'origin');
  });

  test('POST works', () async {
    final response = await client.post(server.uri);
    expect(response.statusCode, equals(200));
    print('Response: ${response.body}');
    print('Headers: ${response.headers}');
    expect(response.headers['access-control-allow-origin'], equals('*'));
  });

  test('mirror headers', () async {
    final response = await client
        .post(server.uri, headers: {'access-control-request-headers': 'foo'});
    expect(response.statusCode, equals(200));
    print('Response: ${response.body}');
    print('Headers: ${response.headers}');
    expect(response.headers['access-control-allow-headers'], equals('foo'));
  });
}
