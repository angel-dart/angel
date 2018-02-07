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
      ..get('/foo', () => {'hello': 'world'})
      ..get(
          '/bar',
          (req, ResponseContext res) =>
              res.serialize({'hello': 'world'}, contentType: ContentType.HTML));
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

  test("correct content-type", () async {
    var response = await client.get('$url/foo');
    print('Response: ${response.body}');
    expect(response.headers[HttpHeaders.CONTENT_TYPE],
        contains(ContentType.JSON.mimeType));

    response = await client.get('$url/bar');
    print('Response: ${response.body}');
    expect(response.headers[HttpHeaders.CONTENT_TYPE],
        contains(ContentType.HTML.mimeType));
  });
}
