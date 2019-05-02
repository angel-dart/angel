import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:angel_oauth2/angel_oauth2.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  TestClient client;

  setUp(() async {
    var app = Angel();
    var oauth2 = _AuthorizationServer();

    app.group('/oauth2', (router) {
      router
        ..get('/authorize', oauth2.authorizationEndpoint)
        ..post('/token', oauth2.tokenEndpoint);
    });

    app.logger = Logger('angel_oauth2')
      ..onRecord.listen((rec) {
        print(rec);
        if (rec.error != null) print(rec.error);
        if (rec.stackTrace != null) print(rec.stackTrace);
      });

    app.errorHandler = (e, req, res) async {
      res.json(e.toJson());
    };

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  group('get initial code', () {
    test('invalid client id', () async {
      var response = await client.post('/oauth2/token', body: {
        'client_id': 'barr',
      });
      print(response.body);
      expect(response, hasStatus(400));
    });

    test('valid client id, no scopes', () async {
      var response = await client.post('/oauth2/token', body: {
        'client_id': 'foo',
      });
      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(200),
            isJson({
              "device_code": "foo",
              "user_code": "bar",
              "verification_uri": "https://regiostech.com?scopes",
              "expires_in": 3600
            }),
          ));
    });

    test('valid client id, with scopes', () async {
      var response = await client.post('/oauth2/token', body: {
        'client_id': 'foo',
        'scope': 'bar baz quux',
      });
      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(200),
            isJson({
              "device_code": "foo",
              "user_code": "bar",
              "verification_uri": Uri.parse("https://regiostech.com").replace(
                  queryParameters: {'scopes': 'bar,baz,quux'}).toString(),
              "expires_in": 3600
            }),
          ));
    });
  });

  group('get token', () {
    test('valid device code + timing', () async {
      var response = await client.post('/oauth2/token', body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        'client_id': 'foo',
        'device_code': 'bar',
      });

      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(200),
            isJson({"token_type": "bearer", "access_token": "foo"}),
          ));
    });

    // The rationale for only testing one possible error response is that
    // they all only differ in terms of the `code` string sent down,
    // which is chosen by the end user.
    //
    // The logic for throwing errors and turning them into responses
    // has already been tested.
    test('failure', () async {
      var response = await client.post('/oauth2/token', body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        'client_id': 'foo',
        'device_code': 'brute',
      });

      print(response.body);
      expect(
          response,
          allOf(
            hasStatus(400),
            isJson({
              "error": "slow_down",
              "error_description":
                  "Ho, brother! Ho, whoa, whoa, whoa now! You got too much dip on your chip!"
            }),
          ));
    });
  });
}

class _AuthorizationServer
    extends AuthorizationServer<PseudoApplication, PseudoUser> {
  @override
  PseudoApplication findClient(String clientId) {
    return clientId == pseudoApplication.id ? pseudoApplication : null;
  }

  @override
  Future<bool> verifyClient(
      PseudoApplication client, String clientSecret) async {
    return client.secret == clientSecret;
  }

  @override
  FutureOr<DeviceCodeResponse> requestDeviceCode(PseudoApplication client,
      Iterable<String> scopes, RequestContext req, ResponseContext res) {
    return DeviceCodeResponse(
        'foo',
        'bar',
        Uri.parse('https://regiostech.com')
            .replace(queryParameters: {'scopes': scopes.join(',')}),
        3600);
  }

  @override
  FutureOr<AuthorizationTokenResponse> exchangeDeviceCodeForToken(
      PseudoApplication client,
      String deviceCode,
      String state,
      RequestContext req,
      ResponseContext res) {
    if (deviceCode == 'brute') {
      throw AuthorizationException(ErrorResponse(
          ErrorResponse.slowDown,
          "Ho, brother! Ho, whoa, whoa, whoa now! You got too much dip on your chip!",
          state));
    }

    return AuthorizationTokenResponse('foo');
  }
}
