import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_proxy/angel_proxy.dart';
import 'package:angel_test/angel_test.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'common.dart';

main() {
  Angel app;
  http.Client client = new http.Client();
  HttpServer server, testServer;
  String url;

  setUp(() async {
    app = new Angel()..storeOriginalBuffer = true;

    testServer = await testApp().startServer();

    await app.configure(new ProxyLayer(
        testServer.address.address, testServer.port,
        publicPath: '/proxy',
        routeAssigner: (router, path, handler) => router.all(path, handler)));
    await app.configure(new ProxyLayer(
        testServer.address.address, testServer.port,
        mapTo: '/foo'));

    app.after.add((req, res) async => res.write('intercept empty'));

    server = await app.startServer();
    url = 'http://${server.address.address}:${server.port}';
  });

  tearDown(() async {
    await testServer.close(force: true);
    await server.close(force: true);
    app = null;
    url = null;
  });

  test('publicPath', () async {
    final response = await client.get('$url/proxy/hello');
    print('Response: ${response.body}');
    expect(response.body, equals('"world"'));
  });

  test('empty', () async {
    var response = await client.get('$url/proxy/empty');
    print('Response: ${response.body}');

    // Shouldn't say it is gzipped...
    expect(response, isNot(hasHeader('content-encoding')));

    // Should have gzipped body
    expect(response.body, 'intercept empty');
  });

  test('mapTo', () async {
    final response = await client.get('$url/bar');
    print('Response: ${response.body}');
    expect(response.body, equals('"baz"'));
  });

  test('original buffer', () async {
    var response = await client.post('$url/proxy/body',
        body: {'foo': 'bar'},
        headers: {'content-type': 'application/x-www-form-urlencoded'});
    print('Response: ${response.body}');
    expect(response.body, isNotEmpty);
    expect(JSON.decode(response.body), {'foo': 'bar'});
  });
}
