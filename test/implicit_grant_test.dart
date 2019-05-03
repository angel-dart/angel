import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:angel_oauth2/angel_oauth2.dart';
import 'package:angel_validate/angel_validate.dart';
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

    app.errorHandler = (e, req, res) async {
      res.json(e.toJson());
    };

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('authenticate via implicit grant', () async {
    var response = await client.get(
      '/oauth2/authorize?response_type=token&client_id=foo&redirect_uri=http://foo.com&state=bar',
    );

    print('Headers: ${response.headers}');
    expect(
        response,
        allOf(
          hasStatus(302),
          hasHeader('location',
              'http://foo.com#access_token=foo&token_type=bearer&state=bar'),
        ));
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
  Future<void> requestAuthorizationCode(
      PseudoApplication client,
      String redirectUri,
      Iterable<String> scopes,
      String state,
      RequestContext req,
      ResponseContext res,
      bool implicit) async {
    var tok = AuthorizationTokenResponse('foo');
    var uri = completeImplicitGrant(tok, Uri.parse(redirectUri), state: state);
    return res.redirect(uri);
  }
}
