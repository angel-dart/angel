import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:matcher/matcher.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

final Uri $foo = Uri.parse('http://localhost:3000/foo');

/// Additional tests to improve coverage of server.dart
main() {
  group('scoping', () {
    var parent = new Angel()..configuration['two'] = 2;
    var child = new Angel();
    parent.use('/child', child);

    test('sets children', () {
      expect(parent.children, contains(child));
    });

    test('sets parent', () {
      expect(child.parent, parent);
    });

    test('properties can climb up hierarchy', () {
      expect(child.findProperty('two'), 2);
    });
  });

  test('custom server generator', () {
    var app = new Angel.custom(HttpServer.bind);
    expect(app.serverGenerator, HttpServer.bind);
  });

  test('default error handler', () async {
    var app = new Angel();
    var rq = new MockHttpRequest('GET', $foo);
    rq.close();
    var rs = rq.response;
    var req = await app.createRequestContext(rq);
    var res = await app.createResponseContext(rs);
    var e = new AngelHttpException(null,
        statusCode: 321, message: 'Hello', errors: ['foo', 'bar']);
    await app.errorHandler(e, req, res);
    await app.sendResponse(rq, req, res);
    expect(rs.headers.value(HttpHeaders.CONTENT_TYPE),
        ContentType.HTML.toString());
    expect(rs.statusCode, e.statusCode);
    var body = await rs.transform(UTF8.decoder).join();
    expect(body, contains('<title>${e.message}</title>'));
    expect(body, contains('<li>foo</li>'));
    expect(body, contains('<li>bar</li>'));
  });

  test('plug-ins run on startup', () async {
    var app = new Angel();
    app.startupHooks.add((app) async {
      app.configuration['two'] = 2;
    });
    await app.startServer();
    expect(app.configuration['two'], 2);
    await app.close();
  });

  test('warning when adding routes to flattened router', () {
    var app = new Angel()..optimizeForProduction(force: true);
    app.dumpTree();
    app.get('/', () => 2);
    app.mount('/foo', new Router()..get('/', 3));
  });

  test('services close on close call', () async {
    var app = new Angel();
    var svc = new CustomCloseService();
    expect(svc.value, 2);
    app.use('/', svc);
    await app.close();
    expect(svc.value, 3);
  });

  test('global injection added to injection map', () async {
    var app = new Angel()..inject('a', 'b');
    app.get('/', (String a) => a);
    var rq = new MockHttpRequest('GET', Uri.parse('/'))..close();
    await app.handleRequest(rq);
    var body = await rq.response.transform(UTF8.decoder).join();
    expect(body, JSON.encode('b'));
  });

  test('global injected serializer', () async {
    var app = new Angel()..injectSerializer((_) => 'x');
    app.get($foo.path, (req, ResponseContext res) => res.serialize(null));
    var rq = new MockHttpRequest('GET', $foo)..close();
    await app.handleRequest(rq);
    var body = await rq.response.transform(UTF8.decoder).join();
    expect(body, 'x');
  });

  group('handler results', () {
    var app = new Angel();
    app.responseFinalizers
        .add((req, res) => throw new AngelHttpException.forbidden());
    RequestContext req;
    ResponseContext res;

    setUp(() async {
      var rq = new MockHttpRequest('GET', $foo)..close();
      req = await app.createRequestContext(rq);
      res = await app.createResponseContext(rq.response);
    });

    group('getHandlerResult', () {
      test('return request handler', () async {
        var handler = (req, res) => (req, res) async {
              return 2;
            };
        var r = await app.getHandlerResult(handler, req, res);
        expect(r, 2);
      });

      test('return future', () async {
        var handler = new Future.value(2);
        expect(await app.getHandlerResult(handler, req, res), 2);
      });
    });

    group('executeHandler', () {
      test('return Stream', () async {
        var handler = (req, res) => new Stream.fromIterable([2, 3]);
        expect(await app.executeHandler(handler, req, res), isFalse);
      });

      test('end response', () async {
        var handler = (req, res) => res.end();
        expect(await app.executeHandler(handler, req, res), isFalse);
      });
    });
  });

  group('handleAngelHttpException', () {
    Angel app;

    setUp(() async {
      app = new Angel();
      app.get('/wtf', () => throw new AngelHttpException.forbidden());
      app.get('/wtf2', () => throw new AngelHttpException.forbidden());
      await app.startServer(InternetAddress.LOOPBACK_IP_V4, 0);

      var oldHandler = app.errorHandler;
      app.errorHandler = (e, req, res) {
        print('FATAL: ${e.error ?? e}');
        print(e.stackTrace);
        return oldHandler(e, req, res);
      };
    });

    tearDown(() => app.close());

    test('can send json', () async {
      var rq = new MockHttpRequest('GET', new Uri(path: 'wtf'))
        ..headers.set(HttpHeaders.ACCEPT, ContentType.JSON.toString());
      rq.close();
      await app.handleRequest(rq);
      expect(rq.response.statusCode, HttpStatus.FORBIDDEN);
      expect(
          rq.response.headers.contentType.mimeType, ContentType.JSON.mimeType);
    });

    test('can throw in finalizer', () async {
      var rq = new MockHttpRequest('GET', new Uri(path: 'wtf'))
        ..headers.set(HttpHeaders.ACCEPT, ContentType.JSON.toString());
      rq.close();
      await app.handleRequest(rq);
      expect(rq.response.statusCode, HttpStatus.FORBIDDEN);
      expect(
          rq.response.headers.contentType.mimeType, ContentType.JSON.mimeType);
    });

    test('can send html', () async {
      var rq = new MockHttpRequest('GET', new Uri(path: 'wtf2'));
      rq.headers.set(HttpHeaders.ACCEPT, ContentType.HTML.toString());
      rq.close();
      await app.handleRequest(rq);
      expect(rq.response.statusCode, HttpStatus.FORBIDDEN);
      expect(
          rq.response.headers.contentType?.mimeType, ContentType.HTML.mimeType);
    });
  });
}

class CustomCloseService extends Service {
  int value = 2;

  @override
  Future close() {
    value = 3;
    return super.close();
  }
}

@Expose('/foo')
class FooController extends Controller {
  @Expose('/bar')
  bar() async => 'baz';
}
