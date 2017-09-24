import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_proxy/angel_proxy.dart';
import 'package:angel_test/angel_test.dart';
import 'package:http/http.dart' as http;
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

main() {
  Angel app, testApp;
  TestClient client;

  setUp(() async {
    testApp = new Angel();
    testApp.get('/foo', (req, res) async {
      res.write('pub serve');
    });
    testApp.get('/empty', (req, res) => res.end());

    testApp.responseFinalizers.add((req, ResponseContext res) async {
      print('OUTGOING: ' + new String.fromCharCodes(res.buffer.toBytes()));
    });

    testApp.injectEncoders({'gzip': GZIP.encoder});

    var server = await testApp.startServer();

    app = new Angel();
    app.get('/bar', (req, res) => res.write('normal'));

    var httpClient = new http.Client();

    var layer = new Proxy(
      app,
      httpClient,
      server.address.address,
      port: server.port,
      publicPath: '/proxy',
    );
    app.use(layer.handleRequest);

    app.responseFinalizers.add((req, ResponseContext res) async {
      print('Normal. Buf: ' +
          new String.fromCharCodes(res.buffer.toBytes()) +
          ', headers: ${res.headers}');
    });

    app.injectEncoders({'gzip': GZIP.encoder});

    client = await connectTo(app);
  });

  tearDown(() async {
    await client.close();
    await app.close();
    await testApp.close();
    app = null;
    testApp = null;
  });

  test('proxied', () async {
    var rq = new MockHttpRequest('GET', Uri.parse('/proxy/foo'))..close();
    await app.handleRequest(rq);
    var response = await rq.response.transform(UTF8.decoder).join();
    expect(response, 'pub serve');
  });

  test('empty', () async {
    var response = await client.get('/proxy/empty');
    expect(response.body, isEmpty);
  });

  test('normal', () async {
    var response = await client.get('/bar');
    expect(response, hasBody('normal'));
  });
}
