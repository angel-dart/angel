// ignore_for_file: todo
import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_oauth2/angel_oauth2.dart';

main() async {
  var app = Angel();
  var oauth2 = _ExampleAuthorizationServer();
  var _rgxBearer = RegExp(r'^[Bb]earer ([^\n\s]+)$');

  app.group('/auth', (router) {
    router
      ..get('/authorize', oauth2.authorizationEndpoint)
      ..post('/token', oauth2.tokenEndpoint);
  });

  // Assume that all other requests must be authenticated...
  app.fallback((req, res) {
    var authToken =
        req.headers.value('authorization')?.replaceAll(_rgxBearer, '')?.trim();

    if (authToken == null) {
      throw AngelHttpException.forbidden();
    } else {
      // TODO: The user has a token, now verify it.
      // It is up to you how to store and retrieve auth tokens within your application.
      // The purpose of `package:angel_oauth2` is to provide the transport
      // across which you distribute these tokens in the first place.
    }
  });
}

class ThirdPartyApp {}

class User {}

/// A [ThirdPartyApp] can act on behalf of a [User].
class _ExampleAuthorizationServer
    extends AuthorizationServer<ThirdPartyApp, User> {
  @override
  FutureOr<ThirdPartyApp> findClient(String clientId) {
    // TODO: Add your code to find the app associated with a client ID.
    throw UnimplementedError();
  }

  @override
  FutureOr<bool> verifyClient(ThirdPartyApp client, String clientSecret) {
    // TODO: Add your code to verify a client secret, if given one.
    throw UnimplementedError();
  }

  @override
  FutureOr requestAuthorizationCode(
      ThirdPartyApp client,
      String redirectUri,
      Iterable<String> scopes,
      String state,
      RequestContext req,
      ResponseContext res,
      bool implicit) {
    // TODO: In many cases, here you will render a view displaying to the user which scopes are being requested.
    throw UnimplementedError();
  }

  @override
  FutureOr<AuthorizationTokenResponse> exchangeAuthorizationCodeForToken(
      ThirdPartyApp client,
      String authCode,
      String redirectUri,
      RequestContext req,
      ResponseContext res) {
    // TODO: Here, you'll convert the auth code into a full-fledged token.
    // You might have the auth code stored in a database somewhere.
    throw UnimplementedError();
  }
}
