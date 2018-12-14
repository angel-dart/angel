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
    var app = new Angel();
    var oauth2 = new _AuthorizationServer();

    app.group('/oauth2', (router) {
      router
        ..get('/authorize', oauth2.authorizationEndpoint)
        ..post('/token', oauth2.tokenEndpoint);
    });

    app.logger = new Logger('angel_oauth2')
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
    return new DeviceCodeResponse(
        'foo',
        'bar',
        Uri.parse('https://regiostech.com')
            .replace(queryParameters: {'scopes': scopes.join(',')}),
        3600);
  }

  @override
  Future<AuthorizationTokenResponse> implicitGrant(
      PseudoApplication client,
      String redirectUri,
      Iterable<String> scopes,
      String state,
      RequestContext req,
      ResponseContext res) async {
    return new AuthorizationTokenResponse('foo');
  }
}
