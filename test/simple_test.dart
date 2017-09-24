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
      ..get('/hello', 'Hello')
      ..get(
          '/error',
          () => throw new AngelHttpException.forbidden(message: 'Test')
            ..errors.addAll(['foo', 'bar']))
      ..get('/body', (ResponseContext res) {
        res
          ..write('OK')
          ..end();
      })
      ..get(
          '/valid',
          () => {
                'michael': 'jackson',
                'billie': {'jean': 'hee-hee', 'is_my_lover': false}
              })
      ..post('/hello', (req, res) async {
        return {'bar': req.body['foo']};
      })
      ..get('/gzip', (req, res) async {
        res
          ..headers[HttpHeaders.CONTENT_ENCODING] = 'gzip'
          ..write(GZIP.encode('Poop'.codeUnits))
          ..end();
      })
      ..use(
          '/foo',
          new AnonymousService(
              index: ([params]) async => [
                    {'michael': 'jackson'}
                  ],
              create: (data, [params]) async => {'foo': 'bar'}));

    var ws = new AngelWebSocket(app);
    await app.configure(ws.configureServer);
    app.all('/ws', ws.handleRequest);

    client = await connectTo(app);
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
      expect(res, isAngelHttpException());
      expect(
          res,
          isAngelHttpException(
              statusCode: 403, message: 'Test', errors: ['foo', 'bar']));
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
      expect(res, hasContentType('application/json'));
      expect(res, hasContentType(ContentType.JSON));
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
      expect(res, hasHeader(HttpHeaders.CONTENT_ENCODING, 'gzip'));
      expect(res, hasBody('Poop'));
    });

    group('service', () {
      test('index', () async {
        var foo = client.service('foo');
        var result = await foo.index();
        expect(result, [
          {'michael': 'jackson'}
        ]);
      });

      test('index', () async {
        var foo = client.service('foo');
        var result = await foo.create({});
        expect(result, {'foo': 'bar'});
      });
    });

    test('websocket', () async {
      var ws = await client.websocket();
      var foo = ws.service('foo');
      foo.create({});
      var result = await foo.onCreated.first;
      expect(result.data, equals({'foo': 'bar'}));
    });
  });
}
