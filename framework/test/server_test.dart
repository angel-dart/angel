import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:matcher/matcher.dart';
import 'package:mock_request/mock_request.dart';

import 'package:test/test.dart';

final Uri $foo = Uri.parse('http://localhost:3000/foo');

/// Additional tests to improve coverage of server.dart
main() {
  group('scoping', () {
    var parent = Angel(reflector: MirrorsReflector())..configuration['two'] = 2;
    var child = Angel(reflector: MirrorsReflector());
    parent.mount('/child', child);

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
    var app = Angel(reflector: MirrorsReflector());
    var http = AngelHttp.custom(app, HttpServer.bind);
    expect(http.serverGenerator, HttpServer.bind);
  });

  test('default error handler', () async {
    var app = Angel(reflector: MirrorsReflector());
    var http = AngelHttp(app);
    var rq = MockHttpRequest('GET', $foo);
    (rq.close());
    var rs = rq.response;
    var req = await http.createRequestContext(rq, rs);
    var res = await http.createResponseContext(rq, rs);
    var e = AngelHttpException(null,
        statusCode: 321, message: 'Hello', errors: ['foo', 'bar']);
    await app.errorHandler(e, req, res);
    await http.sendResponse(rq, rs, req, res);
    expect(
      ContentType.parse(rs.headers.value('content-type')).mimeType,
      'text/html',
    );
    expect(rs.statusCode, e.statusCode);
    var body = await rs.transform(utf8.decoder).join();
    expect(body, contains('<title>${e.message}</title>'));
    expect(body, contains('<li>foo</li>'));
    expect(body, contains('<li>bar</li>'));
  });

  test('plug-ins run on startup', () async {
    var app = Angel(reflector: MirrorsReflector());
    app.startupHooks.add((app) => app.configuration['two'] = 2);

    var http = AngelHttp(app);
    await http.startServer();
    expect(app.configuration['two'], 2);
    await app.close();
    await http.close();
  });

  test('warning when adding routes to flattened router', () {
    var app = Angel(reflector: MirrorsReflector())
      ..optimizeForProduction(force: true);
    app.dumpTree();
    app.get('/', (req, res) => 2);
    app.mount('/foo', Router()..get('/', (req, res) => 3));
  });

  test('services close on close call', () async {
    var app = Angel(reflector: MirrorsReflector());
    var svc = CustomCloseService();
    expect(svc.value, 2);
    app.use('/', svc);
    await app.close();
    expect(svc.value, 3);
  });

  test('global injection added to injection map', () async {
    var app = Angel(reflector: MirrorsReflector())..configuration['a'] = 'b';
    var http = AngelHttp(app);
    app.get('/', ioc((String a) => a));
    var rq = MockHttpRequest('GET', Uri.parse('/'));
    (rq.close());
    await http.handleRequest(rq);
    var body = await rq.response.transform(utf8.decoder).join();
    expect(body, json.encode('b'));
  });

  test('global injected serializer', () async {
    var app = Angel(reflector: MirrorsReflector())..serializer = (_) => 'x';
    var http = AngelHttp(app);
    app.get($foo.path, (req, ResponseContext res) => res.serialize(null));
    var rq = MockHttpRequest('GET', $foo);
    (rq.close());
    await http.handleRequest(rq);
    var body = await rq.response.transform(utf8.decoder).join();
    expect(body, 'x');
  });

  group('handler results', () {
    var app = Angel(reflector: MirrorsReflector());
    var http = AngelHttp(app);
    app.responseFinalizers
        .add((req, res) => throw AngelHttpException.forbidden());
    RequestContext req;
    ResponseContext res;

    setUp(() async {
      var rq = MockHttpRequest('GET', $foo);
      (rq.close());
      req = await http.createRequestContext(rq, rq.response);
      res = await http.createResponseContext(rq, rq.response);
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
        var handler = Future.value(2);
        expect(await app.getHandlerResult(handler, req, res), 2);
      });
    });

    group('executeHandler', () {
      test('return Stream', () async {
        var handler = (req, res) => Stream.fromIterable([2, 3]);
        expect(await app.executeHandler(handler, req, res), isFalse);
      });

      test('end response', () async {
        var handler = (req, ResponseContext res) => res.close();
        expect(await app.executeHandler(handler, req, res), isFalse);
      });
    });
  });

  group('handleAngelHttpException', () {
    Angel app;
    AngelHttp http;

    setUp(() async {
      app = Angel(reflector: MirrorsReflector());
      app.get('/wtf', (req, res) => throw AngelHttpException.forbidden());
      app.get('/wtf2', (req, res) => throw AngelHttpException.forbidden());
      http = AngelHttp(app);
      await http.startServer('127.0.0.1', 0);

      var oldHandler = app.errorHandler;
      app.errorHandler = (e, req, res) {
        print('FATAL: ${e.error ?? e}');
        print(e.stackTrace);
        return oldHandler(e, req, res);
      };
    });

    tearDown(() => app.close());

    test('can send json', () async {
      var rq = MockHttpRequest('GET', Uri(path: 'wtf'))
        ..headers.set('accept', 'application/json');
      (rq.close());
      (http.handleRequest(rq));
      await rq.response.toList();
      expect(rq.response.statusCode, 403);
      expect(rq.response.headers.contentType.mimeType, 'application/json');
    });

    test('can throw in finalizer', () async {
      var rq = MockHttpRequest('GET', Uri(path: 'wtf'))
        ..headers.set('accept', 'application/json');
      (rq.close());
      (http.handleRequest(rq));
      await rq.response.toList();
      expect(rq.response.statusCode, 403);
      expect(rq.response.headers.contentType.mimeType, 'application/json');
    });

    test('can send html', () async {
      var rq = MockHttpRequest('GET', Uri(path: 'wtf2'));
      rq.headers.set('accept', 'text/html');
      (rq.close());
      (http.handleRequest(rq));
      await rq.response.toList();
      expect(rq.response.statusCode, 403);
      expect(rq.response.headers.contentType?.mimeType, 'text/html');
    });
  });
}

class CustomCloseService extends Service {
  int value = 2;

  @override
  void close() {
    value = 3;
    super.close();
  }
}

@Expose('/foo')
class FooController extends Controller {
  @Expose('/bar')
  bar() async => 'baz';
}
