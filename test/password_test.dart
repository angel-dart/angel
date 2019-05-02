import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_oauth2/angel_oauth2.dart';
import 'package:logging/logging.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:test/test.dart';
import 'common.dart';

main() {
  Angel app;
  Uri tokenEndpoint;

  setUp(() async {
    app = Angel();
    var auth = _AuthorizationServer();

    app.group('/oauth2', (router) {
      router
        ..get('/authorize', auth.authorizationEndpoint)
        ..post('/token', auth.tokenEndpoint);
    });

    app.errorHandler = (e, req, res) async {
      res.json(e.toJson());
    };

    app.logger = Logger('password_test')..onRecord.listen(print);

    var http = AngelHttp(app);
    var server = await http.startServer();
    var url = 'http://${server.address.address}:${server.port}';
    tokenEndpoint = Uri.parse('$url/oauth2/token');
  });

  tearDown(() => app.close());

  test('authenticate via username+password', () async {
    var client = await oauth2.resourceOwnerPasswordGrant(
      tokenEndpoint,
      'michael',
      'jackson',
      identifier: 'foo',
      secret: 'bar',
    );
    print(client.credentials.toJson());
    client.close();
    expect(client.credentials.accessToken, 'foo');
    expect(client.credentials.refreshToken, 'bar');
  });

  test('force correct username+password', () async {
    oauth2.Client client;

    try {
      client = await oauth2.resourceOwnerPasswordGrant(
        tokenEndpoint,
        'michael',
        'jordan',
        identifier: 'foo',
        secret: 'bar',
      );

      throw StateError('should fail');
    } on oauth2.AuthorizationException catch (e) {
      expect(e.error, ErrorResponse.accessDenied);
    } finally {
      client?.close();
    }
  });

  test('can refresh token', () async {
    var client = await oauth2.resourceOwnerPasswordGrant(
      tokenEndpoint,
      'michael',
      'jackson',
      identifier: 'foo',
      secret: 'bar',
    );
    client = await client.refreshCredentials();
    print(client.credentials.toJson());
    client.close();
    expect(client.credentials.accessToken, 'baz');
    expect(client.credentials.refreshToken, 'bar');
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
  Future<AuthorizationTokenResponse> refreshAuthorizationToken(
      PseudoApplication client,
      String refreshToken,
      Iterable<String> scopes,
      RequestContext req,
      ResponseContext res) async {
    return AuthorizationTokenResponse('baz', refreshToken: 'bar');
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
      var body = await req.parseBody().then((_) => req.bodyAsMap);
      throw AuthorizationException(
        ErrorResponse(
          ErrorResponse.accessDenied,
          'Invalid username or password.',
          body['state']?.toString() ?? '',
        ),
        statusCode: 401,
      );
    }

    return AuthorizationTokenResponse('foo', refreshToken: 'bar');
  }
}
