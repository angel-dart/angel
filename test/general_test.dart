import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

main() {
  Angel app;
  http.Client client;
  HttpServer server;
  String url;

  setUp(() async {
    app = new Angel()
      ..post('/foo', () => {'hello': 'world'})
      ..all('*', () => throw new AngelHttpException.notFound());
    client = new http.Client();

    server = await new AngelHttp(app).startServer();
    url = "http://${server.address.host}:${server.port}";
  });

  tearDown(() async {
    app = null;
    url = null;
    client.close();
    client = null;
    await server.close(force: true);
  });

  test("allow override of method", () async {
    var response = await client
        .get('$url/foo', headers: {'X-HTTP-Method-Override': 'POST'});
    print('Response: ${response.body}');
    expect(JSON.decode(response.body), equals({'hello': 'world'}));
  });
}
