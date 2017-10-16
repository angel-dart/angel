import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:angel_oauth2/angel_oauth2.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  TestClient client;

  setUp(() async {
    var app = new Angel()..lazyParseBodies = true;
    var oauth2 = new _AuthorizationServer();

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

  test('authenticate via username+password', () async {
    var response = await client.post(
      '/oauth2/token',
      headers: {
        'Authorization': 'Basic ' + BASE64URL.encode('foo:bar'.codeUnits),
      },
      body: {
        'grant_type': 'password',
        'username': 'michael',
        'password': 'jackson',
      },
    );

    print('Response: ${response.body}');

    expect(response, allOf(
      hasStatus(200),
      hasContentType(ContentType.JSON),
      hasValidBody(new Validator({
        'token_type': equals('bearer'),
        'access_token': equals('foo'),
      })),
    ));
  });

  test('force correct username+password', () async {
    var response = await client.post(
      '/oauth2/token',
      headers: {
        'Authorization': 'Basic ' + BASE64URL.encode('foo:bar'.codeUnits),
      },
      body: {
        'grant_type': 'password',
        'username': 'michael',
        'password': 'jordan',
      },
    );

    print('Response: ${response.body}');
    expect(response, hasStatus(401));
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
  Future<AuthorizationTokenResponse> resourceOwnerPasswordCredentialsGrant(
      PseudoApplication client,
      String username,
      String password,
      Iterable<String> scopes,
      RequestContext req,
      ResponseContext res) async {
    var user = pseudoUsers.firstWhere(
        (u) => u.username == username && u.password == password,
        orElse: () => null);

    if (user == null) {
      throw new AuthorizationException(
        new ErrorResponse(
          ErrorResponse.accessDenied,
          'Invalid username or password.',
          req.body['state'] ?? '',
        ),
        statusCode: 401,
      );
    }

    return new AuthorizationTokenResponse('foo');
  }
}
