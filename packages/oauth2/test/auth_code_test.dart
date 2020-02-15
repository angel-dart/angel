import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_oauth2/angel_oauth2.dart';
import 'package:angel_test/angel_test.dart';
import 'package:logging/logging.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'common.dart';

main() {
  Angel app;
  Uri authorizationEndpoint, tokenEndpoint, redirectUri;
  TestClient testClient;

  setUp(() async {
    app = Angel();
    app.configuration['properties'] = app.configuration;
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
    redirectUri = Uri.parse('http://foo.bar/baz');

    testClient = await connectTo(app);
  });

  tearDown(() async {
    await testClient.close();
  });

  group('auth code', () {
    oauth2.AuthorizationCodeGrant createGrant() =>
        oauth2.AuthorizationCodeGrant(
          pseudoApplication.id,
          authorizationEndpoint,
          tokenEndpoint,
          secret: pseudoApplication.secret,
        );

    test('show authorization form', () async {
      var grant = createGrant();
      var url = grant.getAuthorizationUrl(redirectUri, state: 'hello');
      var response = await testClient.client.get(url);
      print('Body: ${response.body}');
      expect(
          response.body,
          json.encode(
              'Hello ${pseudoApplication.id}:${pseudoApplication.secret}'));
    });

    test('preserves state', () async {
      var grant = createGrant();
      var url = grant.getAuthorizationUrl(redirectUri, state: 'goodbye');
      var response = await testClient.client.get(url);
      print('Body: ${response.body}');
      expect(json.decode(response.body)['state'], 'goodbye');
    });

    test('sends auth code', () async {
      var grant = createGrant();
      var url = grant.getAuthorizationUrl(redirectUri);
      var response = await testClient.client.get(url);
      print('Body: ${response.body}');
      expect(
        json.decode(response.body),
        allOf(
          isMap,
          predicate((Map m) => m.containsKey('code'), 'contains "code"'),
        ),
      );
    });

    test('exchange code for token', () async {
      var grant = createGrant();
      var url = grant.getAuthorizationUrl(redirectUri);
      var response = await testClient.client.get(url);
      print('Body: ${response.body}');

      var authCode = json.decode(response.body)['code'].toString();
      var client = await grant.handleAuthorizationCode(authCode);
      expect(client.credentials.accessToken, authCode + '_access');
    });

    test('can send refresh token', () async {
      var grant = createGrant();
      var url = grant.getAuthorizationUrl(redirectUri, state: 'can_refresh');
      var response = await testClient.client.get(url);
      print('Body: ${response.body}');

      var authCode = json.decode(response.body)['code'].toString();
      var client = await grant.handleAuthorizationCode(authCode);
      expect(client.credentials.accessToken, authCode + '_access');
      expect(client.credentials.canRefresh, isTrue);
      expect(client.credentials.refreshToken, authCode + '_refresh');
    });
  });
}

class _Server extends AuthorizationServer<PseudoApplication, Map> {
  final Uuid _uuid = Uuid();

  @override
  FutureOr<PseudoApplication> findClient(String clientId) {
    return clientId == pseudoApplication.id ? pseudoApplication : null;
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
    if (implicit) {
      // Throw the default error on an implicit grant attempt.
      return super.requestAuthorizationCode(
          client, redirectUri, scopes, state, req, res, implicit);
    }

    if (state == 'hello')
      return 'Hello ${pseudoApplication.id}:${pseudoApplication.secret}';

    var authCode = _uuid.v4();
    var authCodes = req.container.make<AuthCodes>();
    authCodes[authCode] = state;

    res.headers['content-type'] = 'application/json';
    var result = {'code': authCode};
    if (state?.isNotEmpty == true) result['state'] = state;
    return result;
  }

  @override
  Future<AuthorizationTokenResponse> exchangeAuthorizationCodeForToken(
      PseudoApplication client,
      String authCode,
      String redirectUri,
      RequestContext req,
      ResponseContext res) async {
    var authCodes = req.container.make<AuthCodes>();
    var state = authCodes[authCode];
    var refreshToken = state == 'can_refresh' ? '${authCode}_refresh' : null;
    return AuthorizationTokenResponse('${authCode}_access',
        refreshToken: refreshToken);
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
