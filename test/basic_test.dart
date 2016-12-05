import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_cors/angel_cors.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

main() {
  Angel app;
  http.Client client;
  HttpServer server;
  String url;

  setUp(() async {
    app = new Angel()
      ..before.add(cors())
      ..post('/', (req, res) async {
        res.write('hello world');
        return false;
      })
      ..all('*', () {
        throw new AngelHttpException.NotFound();
      });

    server = await app.startServer();
    url = 'http://${server.address.address}:${server.port}';
    client = new http.Client();
  });

  tearDown(() async {
    await server.close(force: true);
    app = null;
    client = null;
    url = null;
  });

  test('POST works', () async {
    final response = await client.post(url);
    expect(response.statusCode, equals(200));
    print('Response: ${response.body}');
    print('Headers: ${response.headers}');
    expect(response.headers['access-control-allow-origin'], equals('*'));
  });
}
