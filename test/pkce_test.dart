import 'dart:async';
import 'dart:collection';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_oauth2/angel_oauth2.dart';
import 'package:angel_test/angel_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  Angel app;
  Uri authorizationEndpoint, tokenEndpoint;
  TestClient testClient;

  setUp(() async {
    app = Angel();
    app.container.registerSingleton(AuthCodes());

    var server = _Server();

    app.group('/oauth2', (router) {
      router
        ..get('/authorize', server.authorizationEndpoint)
        ..post('/token', server.tokenEndpoint);
    });

    app.logger = Logger('angel')
      ..onRecord.listen((rec) {
        print(rec);
        if (rec.error != null) print(rec.error);
        if (rec.stackTrace != null) print(rec.stackTrace);
      });

    var http = AngelHttp(app);
    var s = await http.startServer();
    var url = 'http://${s.address.address}:${s.port}';
    authorizationEndpoint = Uri.parse('$url/oauth2/authorize');
    tokenEndpoint = Uri.parse('$url/oauth2/token');

    testClient = await connectTo(app);
  });

  tearDown(() async {
    await testClient.close();
  });

  group('get auth code', () {
    test('with challenge + implied plain', () async {
      var url = authorizationEndpoint.replace(queryParameters: {
        'response_type': 'code',
        'client_id': 'freddie mercury',
        'redirect_uri': 'https://freddie.mercu.ry',
        'code_challenge': 'foo',
      });
      var response = await testClient
          .get(url.toString(), headers: {'accept': 'application/json'});
      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(200),
            isJson({"code": "ok"}),
          ));
    });

    test('with challenge + plain', () async {
      var url = authorizationEndpoint.replace(queryParameters: {
        'response_type': 'code',
        'client_id': 'freddie mercury',
        'redirect_uri': 'https://freddie.mercu.ry',
        'code_challenge': 'foo',
        'code_challenge_method': 'plain',
      });
      var response = await testClient
          .get(url.toString(), headers: {'accept': 'application/json'});
      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(200),
            isJson({"code": "ok"}),
          ));
    });

    test('with challenge + s256', () async {
      var url = authorizationEndpoint.replace(queryParameters: {
        'response_type': 'code',
        'client_id': 'freddie mercury',
        'redirect_uri': 'https://freddie.mercu.ry',
        'code_challenge': 'foo',
        'code_challenge_method': 's256',
      });
      var response = await testClient
          .get(url.toString(), headers: {'accept': 'application/json'});
      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(200),
            isJson({"code": "ok"}),
          ));
    });

    test('with challenge + wrong method', () async {
      var url = authorizationEndpoint.replace(queryParameters: {
        'response_type': 'code',
        'client_id': 'freddie mercury',
        'redirect_uri': 'https://freddie.mercu.ry',
        'code_challenge': 'foo',
        'code_challenge_method': 'bar',
      });
      var response = await testClient
          .get(url.toString(), headers: {'accept': 'application/json'});
      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(400),
            isJson({
              "error": "invalid_request",
              "error_description":
                  "The `code_challenge_method` parameter must be either 'plain' or 's256'."
            }),
          ));
    });

    test('with no challenge', () async {
      var url = authorizationEndpoint.replace(queryParameters: {
        'response_type': 'code',
        'client_id': 'freddie mercury',
        'redirect_uri': 'https://freddie.mercu.ry'
      });
      var response = await testClient
          .get(url.toString(), headers: {'accept': 'application/json'});
      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(400),
            isJson({
              "error": "invalid_request",
              "error_description": "Missing `code_challenge` parameter."
            }),
          ));
    });
  });

  group('get token', () {
    test('with correct verifier', () async {
      var url = tokenEndpoint.replace(
          userInfo: '${pseudoApplication.id}:${pseudoApplication.secret}');
      var response = await testClient.post(url.toString(), headers: {
        'accept': 'application/json',
        // 'authorization': 'Basic ' + base64Url.encode(ascii.encode(url.userInfo))
      }, body: {
        'grant_type': 'authorization_code',
        'client_id': 'freddie mercury',
        'redirect_uri': 'https://freddie.mercu.ry',
        'code': 'ok',
        'code_verifier': 'hello',
      });

      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(200),
            isJson({"token_type": "bearer", "access_token": "yes"}),
          ));
    });
    test('with incorrect verifier', () async {
      var url = tokenEndpoint.replace(
          userInfo: '${pseudoApplication.id}:${pseudoApplication.secret}');
      var response = await testClient.post(url.toString(), headers: {
        'accept': 'application/json',
        // 'authorization': 'Basic ' + base64Url.encode(ascii.encode(url.userInfo))
      }, body: {
        'grant_type': 'authorization_code',
        'client_id': 'freddie mercury',
        'redirect_uri': 'https://freddie.mercu.ry',
        'code': 'ok',
        'code_verifier': 'foo',
      });

      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(400),
            isJson({
              "error": "invalid_grant",
              "error_description":
                  "The given `code_verifier` parameter is invalid."
            }),
          ));
    });

    test('with missing verifier', () async {
      var url = tokenEndpoint.replace(
          userInfo: '${pseudoApplication.id}:${pseudoApplication.secret}');
      var response = await testClient.post(url.toString(), headers: {
        'accept': 'application/json',
        // 'authorization': 'Basic ' + base64Url.encode(ascii.encode(url.userInfo))
      }, body: {
        'grant_type': 'authorization_code',
        'client_id': 'freddie mercury',
        'redirect_uri': 'https://freddie.mercu.ry',
        'code': 'ok'
      });

      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(400),
            isJson({
              "error": "invalid_request",
              "error_description": "Missing `code_verifier` parameter."
            }),
          ));
    });
  });
}

class _Server extends AuthorizationServer<PseudoApplication, Map> {
  @override
  FutureOr<PseudoApplication> findClient(String clientId) {
    return pseudoApplication;
  }

  @override
  Future<bool> verifyClient(
      PseudoApplication client, String clientSecret) async {
    return client.secret == clientSecret;
  }

  @override
  Future requestAuthorizationCode(
      PseudoApplication client,
      String redirectUri,
      Iterable<String> scopes,
      String state,
      RequestContext req,
      ResponseContext res,
      bool implicit) async {
    req.container.make<Pkce>();
    return {'code': 'ok'};
  }

  @override
  Future<AuthorizationTokenResponse> exchangeAuthorizationCodeForToken(
      PseudoApplication client,
      String authCode,
      String redirectUri,
      RequestContext req,
      ResponseContext res) async {
    var codeVerifier = await getPkceCodeVerifier(req);
    var pkce = Pkce('plain', 'hello');
    pkce.validate(codeVerifier);
    return AuthorizationTokenResponse('yes');
  }
}

class AuthCodes extends MapBase<String, String> with MapMixin<String, String> {
  var inner = <String, String>{};

  @override
  String operator [](Object key) => inner[key];

  @override
  void operator []=(String key, String value) => inner[key] = value;

  @override
  void clear() => inner.clear();

  @override
  Iterable<String> get keys => inner.keys;

  @override
  String remove(Object key) => inner.remove(key);
}
