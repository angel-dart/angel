import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_proxy/angel_proxy.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'common.dart';

main() {
  Angel app;
  http.Client client = new http.Client();
  HttpServer server, testServer;
  String url;

  setUp(() async {
    app = new Angel();

    testServer = await testApp().startServer();

    await app.configure(new ProxyLayer(
        testServer.address.address, testServer.port,
        publicPath: '/proxy'));
    await app.configure(new ProxyLayer(
        testServer.address.address, testServer.port,
        mapTo: '/foo'));

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

  test('mapTo', () async {
    final response = await client.get('$url/bar');
    print('Response: ${response.body}');
    expect(response.body, equals('"baz"'));
  });
}
