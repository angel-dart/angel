import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_proxy/angel_proxy.dart';
import 'package:http/io_client.dart' as http;
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  Angel app;
  var client = http.IOClient();
  HttpServer server, testServer;
  String url;

  setUp(() async {
    app = Angel();
    var appHttp = AngelHttp(app);

    testServer = await startTestServer();

    var proxy1 = Proxy(
      Uri(
          scheme: 'http',
          host: testServer.address.address,
          port: testServer.port),
      publicPath: '/proxy',
    );

    var proxy2 = Proxy(proxy1.baseUrl.replace(path: '/foo'));
    print('Proxy 1 on: ${proxy1.baseUrl}');
    print('Proxy 2 on: ${proxy2.baseUrl}');

    app.all("/proxy/*", proxy1.handleRequest);
    app.all("*", proxy2.handleRequest);

    app.fallback((req, res) {
      print('Intercepting empty from ${req.uri}');
      res.write('intercept empty');
    });

    app.logger = Logger('angel');

    Logger.root.onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });

    await appHttp.startServer();
    url = appHttp.uri.toString();
  });

  tearDown(() async {
    await testServer?.close(force: true);
    await server?.close(force: true);
    app = null;
    url = null;
  });

  test('publicPath', () async {
    final response = await client.get('$url/proxy/hello');
    print('Response: ${response.body}');
    expect(response.body, equals('world'));
  });

  test('empty', () async {
    var response = await client.get('$url/proxy/empty');
    print('Response: ${response.body}');
    expect(response.body, 'intercept empty');
  });

  test('mapTo', () async {
    final response = await client.get('$url/bar');
    print('Response: ${response.body}');
    expect(response.body, equals('baz'));
  });

  test('original buffer', () async {
    var response = await client.post('$url/proxy/body',
        body: json.encode({'foo': 'bar'}),
        headers: {'content-type': 'application/json'});
    print('Response: ${response.body}');
    expect(response.body, isNotEmpty);
    expect(response.body, isNot('intercept empty'));
  });
}
