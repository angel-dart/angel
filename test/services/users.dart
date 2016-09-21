import 'dart:io';
import 'package:angel/angel.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

main() async {
  group('services.users', () {
    Angel app;
    Client client = new Client();
    Map headers = {
      HttpHeaders.ACCEPT: ContentType.JSON.mimeType,
      HttpHeaders.CONTENT_TYPE: ContentType.JSON.mimeType
    };
    HttpServer server;
    String url;

    setUp(() async {
      Angel app = await createServer();
      server = await app.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
      url = "http://localhost:3000";
    });

    tearDown(() async {
      await server.close(force: true);
      client.close();
    });

    test('index users', () async {
      Response response = await client.get("$url/api/users");
      expect(response.statusCode, equals(HttpStatus.OK));
    });
  });
}
