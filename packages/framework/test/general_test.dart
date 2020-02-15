import 'dart:io';
import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

main() {
  Angel app;
  http.Client client;
  HttpServer server;
  String url;

  setUp(() async {
    app = Angel(reflector: MirrorsReflector())
      ..post('/foo', (req, res) => res.serialize({'hello': 'world'}))
      ..all('*', (req, res) => throw AngelHttpException.notFound());
    client = http.Client();

    server = await AngelHttp(app).startServer();
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
    expect(json.decode(response.body), equals({'hello': 'world'}));
  });
}
