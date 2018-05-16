import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:dart2_constant/convert.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

Future<List<int>> getBody(MockHttpResponse rs) async {
  var list = await rs.toList();
  var bb = new BytesBuilder();
  list.forEach(bb.add);
  return bb.takeBytes();
}

main() {
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
    AngelHttp http;

    setUp(() {
      app = getApp();
      http = new AngelHttp(app);
    });

    test('sends plaintext if no accept-encoding', () async {
      var rq = new MockHttpRequest('GET', Uri.parse('/hello'))..close();
      var rs = rq.response;
      await http.handleRequest(rq);

      var body = await rs.transform(utf8.decoder).join();
      expect(body, 'Hello, world!');
    });

    test('encodes if wildcard', () async {
      var rq = new MockHttpRequest('GET', Uri.parse('/hello'))
        ..headers.set(HttpHeaders.ACCEPT_ENCODING, '*')
        ..close();
      var rs = rq.response;
      await http.handleRequest(rq);

      var body = await getBody(rs);
      expect(rs.headers.value(HttpHeaders.CONTENT_ENCODING), 'deflate');
      expect(body, ZLIB.encode(utf8.encode('Hello, world!')));
    });

    test('encodes if wildcard + multiple', () async {
      var rq = new MockHttpRequest('GET', Uri.parse('/hello'))
        ..headers.set(HttpHeaders.ACCEPT_ENCODING, ['foo', 'bar', '*'])
        ..close();
      var rs = rq.response;
      await http.handleRequest(rq);

      var body = await getBody(rs);
      expect(rs.headers.value(HttpHeaders.CONTENT_ENCODING), 'deflate');
      expect(body, ZLIB.encode(utf8.encode('Hello, world!')));
    });

    test('encodes if explicit', () async {
      var rq = new MockHttpRequest('GET', Uri.parse('/hello'))
        ..headers.set(HttpHeaders.ACCEPT_ENCODING, 'gzip');
      await rq.close();
      var rs = rq.response;
      await http.handleRequest(rq);

      var body = await getBody(rs);
      expect(rs.headers.value(HttpHeaders.CONTENT_ENCODING), 'gzip');
      expect(body, GZIP.encode(utf8.encode('Hello, world!')));
    });

    test('only uses one encoder', () async {
      var rq = new MockHttpRequest('GET', Uri.parse('/hello'))
        ..headers.set(HttpHeaders.ACCEPT_ENCODING, ['gzip', 'deflate']);
      await rq.close();
      var rs = rq.response;
      await http.handleRequest(rq);
      
      var body = await getBody(rs);
      expect(rs.headers.value(HttpHeaders.CONTENT_ENCODING), 'gzip');
      expect(body, GZIP.encode(utf8.encode('Hello, world!')));
    });
  });
}
