import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

main() async {
  Angel app;

  setUp(() {
    app = new Angel();
    app.injectEncoders(
      {
        'deflate': ZLIB.encoder,
        'gzip': GZIP.encoder,
      },
    );

    app.get('/hello', (res) {
      res.write('Hello, world!');
    });
  });

  tearDown(() => app.close());

  encodingTests(() => app);
}

void encodingTests(Angel getApp()) {
  group('encoding', () {
    Angel app;

    setUp(() {
      app = getApp();
    });

    test('sends plaintext if no accept-encoding', () async {
      var rq = new MockHttpRequest('GET', Uri.parse('/hello'))..close();
      var rs = rq.response;
      await app.handleRequest(rq);

      var body = await rs.transform(UTF8.decoder).join();
      expect(body, 'Hello, world!');
    });

    test('encodes if wildcard', () async {
      var rq = new MockHttpRequest('GET', Uri.parse('/hello'))
        ..headers.set(HttpHeaders.ACCEPT_ENCODING, '*')
        ..close();
      var rs = rq.response;
      await app.handleRequest(rq);

      var body = await rs.fold<List<int>>([], (out, list) => []..addAll(list));
      expect(rs.headers.value(HttpHeaders.CONTENT_ENCODING), 'deflate');
      expect(body, ZLIB.encode(UTF8.encode('Hello, world!')));
    });

    test('encodes if wildcard + multiple', () async {
      var rq = new MockHttpRequest('GET', Uri.parse('/hello'))
        ..headers.set(HttpHeaders.ACCEPT_ENCODING, ['foo', 'bar', '*'])
        ..close();
      var rs = rq.response;
      await app.handleRequest(rq);

      var body = await rs.fold<List<int>>([], (out, list) => []..addAll(list));
      expect(rs.headers.value(HttpHeaders.CONTENT_ENCODING), 'deflate');
      expect(body, ZLIB.encode(UTF8.encode('Hello, world!')));
    });

    test('encodes if explicit', () async {
      var rq = new MockHttpRequest('GET', Uri.parse('/hello'))
        ..headers.set(HttpHeaders.ACCEPT_ENCODING, 'gzip')
        ..close();
      var rs = rq.response;
      await app.handleRequest(rq);

      var body = await rs.fold<List<int>>([], (out, list) => []..addAll(list));
      expect(rs.headers.value(HttpHeaders.CONTENT_ENCODING), 'gzip');
      expect(body, GZIP.encode(UTF8.encode('Hello, world!')));
    });

    test('only uses one encoder', () async {
      var rq = new MockHttpRequest('GET', Uri.parse('/hello'))
        ..headers.set(HttpHeaders.ACCEPT_ENCODING, ['gzip', 'deflate'])
        ..close();
      var rs = rq.response;
      await app.handleRequest(rq);

      var body = await rs.fold<List<int>>([], (out, list) => []..addAll(list));
      expect(rs.headers.value(HttpHeaders.CONTENT_ENCODING), 'gzip');
      expect(body, GZIP.encode(UTF8.encode('Hello, world!')));
    });
  });
}
