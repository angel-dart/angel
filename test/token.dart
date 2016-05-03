import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_auth/angel_auth.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

wireAuth(Angel app) async {

}

main() async {
  group('token', () {
    Angel app;
    http.Client client;
    String url;

    setUp(() async {
      client = new http.Client();
      app = new Angel();
      await app.configure(wireAuth);
      HttpServer server = await app.startServer(
          InternetAddress.LOOPBACK_IP_V4, 0);
      url = "http://${server.address.host}:${server.port}";
    });

    tearDown(() async {
      await app.httpServer.close(force: true);
      client = null;
      url = null;
    });

    test('can use login as middleware', () async {

    });

    test('successRedirect', () async {

    });

    test('failureRedirect', () async {

    });

    test('allow token', () async {

    });

    test('force token', () async {

    });
  });
}