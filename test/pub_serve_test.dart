import 'dart:convert';
import 'dart:io';
import 'package:angel_compress/angel_compress.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_proxy/angel_proxy.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() {
  Angel app, testApp;
  TestClient client;

  setUp(() async {
    testApp = new Angel();
    testApp.get('/foo', (req, res) => res.write('pub serve'));
    testApp.get('/empty', (req, res) => res.end());
    testApp.responseFinalizers.add(gzip());
    var server = await testApp.startServer();

    app = new Angel();
    app.get('/bar', (req, res) => res.write('normal'));
    var layer = new PubServeLayer(
        debug: true, publicPath: '/proxy', host: server.address.address, port: server.port);
    print('streamToIO: ${layer.streamToIO}');
    await app.configure(layer);

    app.responseFinalizers.add((req, ResponseContext res) async {
      print('Normal. Buf: ' +
          new String.fromCharCodes(res.buffer.toBytes()) +
          ', headers: ${res.headers}');
    });
    app.responseFinalizers.add(gzip());

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
    var response = await client.get('/proxy/foo');

    // Should say it is gzipped...
    expect(response, hasHeader('content-encoding', 'gzip'));

    // Should have gzipped body
    //
    // We have to decode it, because `mock_request` does not auto-decode.
    expect(UTF8.decode(GZIP.decode(response.bodyBytes)), 'pub serve');
  });

  test('empty', () async {
    var response = await client.get('/proxy/empty');

    // Should say it is gzipped...
    expect(response, hasHeader('content-encoding', 'gzip'));

    // Should have gzipped body
    //
    // We have to decode it, because `mock_request` does not auto-decode.
    expect(UTF8.decode(GZIP.decode(response.bodyBytes)), isEmpty);
  });

  test('normal', () async {
    var response = await client.get('/bar');

    // Should say it is gzipped...
    expect(response, hasHeader('content-encoding', 'gzip'));

    // Should have normal body
    //
    // We have to decode it, because `mock_request` does not auto-decode.
    expect(UTF8.decode(GZIP.decode(response.bodyBytes)), 'normal');
  });
}
