import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:angel_websocket/server.dart';
import 'package:test/test.dart';

main() {
  Angel app;
  TestClient client;

  setUp(() async {
    app = new Angel()
      ..get('/hello', (req, res) => 'Hello')
      ..get('/user_info', (req, res) => {'u': req.uri.userInfo})
      ..get(
          '/error',
          (req, res) => throw new AngelHttpException.forbidden(message: 'Test')
            ..errors.addAll(['foo', 'bar']))
      ..get('/body', (req, res) {
        res
          ..write('OK')
          ..close();
      })
      ..get(
          '/valid',
          (req, res) => {
                'michael': 'jackson',
                'billie': {'jean': 'hee-hee', 'is_my_lover': false}
              })
      ..post('/hello', (req, res) async {
        var body = await req.parseBody().then((_) => req.bodyAsMap);
        return {'bar': body['foo']};
      })
      ..get('/gzip', (req, res) async {
        res
          ..headers['content-encoding'] = 'gzip'
          ..add(gzip.encode('Poop'.codeUnits))
          ..close();
      })
      ..use(
          '/foo',
          new AnonymousService<String, Map<String, dynamic>>(
              index: ([params]) async => [
                    <String, dynamic>{'michael': 'jackson'}
                  ],
              create: (data, [params]) async =>
                  <String, dynamic>{'foo': 'bar'}));

    var ws = new AngelWebSocket(app);
    await app.configure(ws.configureServer);
    app.all('/ws', ws.handleRequest);

    app.errorHandler = (e, req, res) => e.toJson();

    client = await connectTo(app, useZone: false);
  });

  tearDown(() async {
    await client.close();
    app = null;
  });

  group('matchers', () {
    group('isJson+hasStatus', () {
      test('get', () async {
        final response = await client.get('/hello');
        expect(response, isJson('Hello'));
      });

      test('post', () async {
        final response = await client.post('/hello', body: {'foo': 'baz'});
        expect(response, allOf(hasStatus(200), isJson({'bar': 'baz'})));
      });
    });

    test('isAngelHttpException', () async {
      var res = await client.get('/error');
      print(res.body);
      expect(res, isAngelHttpException());
      expect(
          res,
          isAngelHttpException(
              statusCode: 403, message: 'Test', errors: ['foo', 'bar']));
    });

    test('userInfo from Uri', () async {
      var url = new Uri(userInfo: 'foo:bar', path: '/user_info');
      print('URL: $url');
      var res = await client.get(url);
      print(res.body);
      var m = json.decode(res.body) as Map;
      expect(m, {'u': 'foo:bar'});
    });

    test('userInfo from Basic auth header', () async {
      var url = new Uri(path: '/user_info');
      print('URL: $url');
      var res = await client.get(url, headers: {
        'authorization': 'Basic ' + (base64Url.encode(utf8.encode('foo:bar')))
      });
      print(res.body);
      var m = json.decode(res.body) as Map;
      expect(m, {'u': 'foo:bar'});
    });

    test('hasBody', () async {
      var res = await client.get('/body');
      expect(res, hasBody());
      expect(res, hasBody('OK'));
    });

    test('hasHeader', () async {
      var res = await client.get('/hello');
      expect(res, hasHeader('server'));
      expect(res, hasHeader('server', 'angel'));
      expect(res, hasHeader('server', ['angel']));
    });

    test('hasValidBody+hasContentType', () async {
      var res = await client.get('/valid');
      print('Body: ${res.body}');
      expect(res, hasContentType('application/json'));
      expect(res, hasContentType(new ContentType('application', 'json')));
      expect(
          res,
          hasValidBody(new Validator({
            'michael*': [isString, isNotEmpty, equals('jackson')],
            'billie': new Validator({
              'jean': [isString, isNotEmpty],
              'is_my_lover': [isBool, isFalse]
            })
          })));
    });

    test('gzip decode', () async {
      var res = await client.get('/gzip');
      print('Body: ${res.body}');
      expect(res, hasHeader('content-encoding', 'gzip'));
      expect(res, hasBody('Poop'));
    });

    group('service', () {
      test('index', () async {
        var foo = client.service('foo');
        var result = await foo.index();
        expect(result, [
          <String, dynamic>{'michael': 'jackson'}
        ]);
      });

      test('index', () async {
        var foo = client.service('foo');
        var result = await foo.create({});
        expect(result, <String, dynamic>{'foo': 'bar'});
      });
    });

    test('websocket', () async {
      var ws = await client.websocket();
      var foo = ws.service('foo');
      foo.create(<String, dynamic>{});
      var result = await foo.onCreated.first;
      expect(result is Map ? result : result.data,
          equals(<String, dynamic>{'foo': 'bar'}));
    });
  });
}
