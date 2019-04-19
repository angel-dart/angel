import 'dart:async';
import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

final AngelAuth<Map<String, String>> auth = AngelAuth<Map<String, String>>();
var headers = <String, String>{'accept': 'application/json'};
var localOpts = AngelAuthOptions<Map<String, String>>(
    failureRedirect: '/failure', successRedirect: '/success');
Map<String, String> sampleUser = {'hello': 'world'};

Future<Map<String, String>> verifier(String username, String password) async {
  if (username == 'username' && password == 'password') {
    return sampleUser;
  } else
    return null;
}

Future wireAuth(Angel app) async {
  auth.serializer = (user) async => 1337;
  auth.deserializer = (id) async => sampleUser;

  auth.strategies['local'] = LocalAuthStrategy(verifier);
  await app.configure(auth.configureServer);
}

main() async {
  Angel app;
  AngelHttp angelHttp;
  http.Client client;
  String url;
  String basicAuthUrl;

  setUp(() async {
    client = http.Client();
    app = Angel();
    angelHttp = AngelHttp(app, useZone: false);
    await app.configure(wireAuth);
    app.get('/hello', (req, res) => 'Woo auth',
        middleware: [auth.authenticate('local')]);
    app.post('/login', (req, res) => 'This should not be shown',
        middleware: [auth.authenticate('local', localOpts)]);
    app.get('/success', (req, res) => "yep", middleware: [
      requireAuthentication<Map<String, String>>(),
    ]);
    app.get('/failure', (req, res) => "nope");

    app.logger = Logger('angel_auth')
      ..onRecord.listen((rec) {
        if (rec.error != null) {
          print(rec.error);
          print(rec.stackTrace);
        }
      });

    HttpServer server = await angelHttp.startServer('127.0.0.1', 0);
    url = "http://${server.address.host}:${server.port}";
    basicAuthUrl =
        "http://username:password@${server.address.host}:${server.port}";
  });

  tearDown(() async {
    await angelHttp.close();
    client = null;
    url = null;
    basicAuthUrl = null;
  });

  test('can use "auth" as middleware', () async {
    var response = await client
        .get("$url/success", headers: {'Accept': 'application/json'});
    print(response.body);
    expect(response.statusCode, equals(403));
  });

  test('successRedirect', () async {
    Map postData = {'username': 'username', 'password': 'password'};
    var response = await client.post("$url/login",
        body: json.encode(postData),
        headers: {'content-type': 'application/json'});
    expect(response.statusCode, equals(302));
    expect(response.headers['location'], equals('/success'));
  });

  test('failureRedirect', () async {
    Map postData = {'username': 'password', 'password': 'username'};
    var response = await client.post("$url/login",
        body: json.encode(postData),
        headers: {'content-type': 'application/json'});
    print("Login response: ${response.body}");
    expect(response.headers['location'], equals('/failure'));
    expect(response.statusCode, equals(401));
  });

  test('allow basic', () async {
    String authString = base64.encode("username:password".runes.toList());
    var response = await client
        .get("$url/hello", headers: {'authorization': 'Basic $authString'});
    expect(response.body, equals('"Woo auth"'));
  });

  test('allow basic via URL encoding', () async {
    var response = await client.get("$basicAuthUrl/hello");
    expect(response.body, equals('"Woo auth"'));
  });

  test('force basic', () async {
    auth.strategies.clear();
    auth.strategies['local'] =
        LocalAuthStrategy(verifier, forceBasic: true, realm: 'test');
    var response = await client.get("$url/hello", headers: {
      'accept': 'application/json',
      'content-type': 'application/json'
    });
    print(response.headers);
    print('Body <${response.body}>');
    expect(response.headers['www-authenticate'], equals('Basic realm="test"'));
  });
}
