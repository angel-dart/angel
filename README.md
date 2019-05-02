# oauth2
[![Pub](https://img.shields.io/pub/v/angel_oauth2.svg)](https://pub.dartlang.org/packages/angel_oauth2)
[![build status](https://travis-ci.org/angel-dart/oauth2.svg)](https://travis-ci.org/angel-dart/oauth2)

A class containing handlers that can be used within
[Angel](https://angel-dart.github.io/) to build a spec-compliant
OAuth 2.0 server, including PKCE support.

* [Installation](#installation)
* [Usage](#usage)
  * [Other Grants](#other-grants)
  * [PKCE](#pkce)

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  angel_framework: ^2.0.0-alpha
  angel_oauth2: ^2.0.0
```

# Usage
Your server needs to have definitions of at least two types:
* One model that represents a third-party application (client) trying to access a user's profile.
* One that represents a user logged into the application.

Define a server class as such:

```dart
import 'package:angel_oauth2/angel_oauth2.dart' as oauth2;

class MyServer extends oauth2.AuthorizationServer<Client, User> {}
```

Then, implement the `findClient` and `verifyClient` to ensure that the
server class can not only identify a client application via a `client_id`,
but that it can also verify its identity via a `client_secret`.

```dart
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
}
```

Next, write some logic to be executed whenever a user visits the
authorization endpoint. In many cases, you will want to show a dialog:

```dart
@override
Future requestAuthorizationCode(
  PseudoApplication client,
  String redirectUri,
  Iterable<String> scopes,
  String state,
  RequestContext req,
  ResponseContext res) async {
  res.render('dialog');
}
```

Now, write logic that exchanges an authorization code for an access token,
and optionally, a refresh token.

```dart
@override
Future<AuthorizationCodeResponse> exchangeAuthCodeForAccessToken(
  String authCode,
  String redirectUri,
  RequestContext req,
  ResponseContext res) async {
    return AuthorizationCodeResponse('foo', refreshToken: 'bar');
}
```

Now, set up some routes to point the server.

```dart
void pseudoCode() {
  app.group('/oauth2', (router) {
    router
      ..get('/authorize', server.authorizationEndpoint)
      ..post('/token', server.tokenEndpoint);
  });
}
```

The `authorizationEndpoint` and `tokenEndpoint` handle all OAuth2 grant types.

## Other Grants
By default, all OAuth2 grant methods will throw a `405 Method Not Allowed` error.
To support any specific grant type, all you need to do is implement the method.
The following are available, not including authorization code grant support (mentioned above):
* `implicitGrant`
* `resourceOwnerPasswordCredentialsGrant`
* `clientCredentialsGrant`
* `deviceCodeGrant`

Read the [OAuth2 specification](https://tools.ietf.org/html/rfc6749)
for in-depth information on each grant type.

## PKCE
In some cases, you will be using OAuth2 on a mobile device, or on some other
public client, where the client cannot have a client
secret.

In such a case, you may consider using
[PKCE](https://tools.ietf.org/html/rfc7636).

Both the `authorizationEndpoint` and `tokenEndpoint`
inject a `Pkce` factory into the request, so it
can be used as follows:

```dart
@override
Future requestAuthorizationCode(
    PseudoApplication client,
    String redirectUri,
    Iterable<String> scopes,
    String state,
    RequestContext req,
    ResponseContext res) async {
  // Automatically throws an error if the request doesn't contain the
  // necessary information.
  var pkce = req.container.make<Pkce>();

  // At this point, store `pkce.codeChallenge` and `pkce.codeChallengeMethod`,
  // so that when it's time to exchange the auth code for a token, we can
  // create a [Pkce] object, and verify the client.
  return await getAuthCodeSomehow(client, pkce.codeChallenge, pkce.codeChallengeMethod); 
}

@override
Future<AuthorizationTokenResponse> exchangeAuthorizationCodeForToken(
    String authCode,
    String redirectUri,
    RequestContext req,
    ResponseContext res) async {
  // When exchanging the authorization code for a token, we'll need
  // a `code_verifier` from the client, so that we can ensure
  // that the correct client is trying to use the auth code.
  //
  // If none is present, an OAuth2 exception is thrown.
  var codeVerifier = await getPkceCodeVerifier(req);

  // Next, we'll need to retrieve the code challenge and code challenge method
  // from earlier.
  var codeChallenge = await getTheChallenge();
  var codeChallengeMethod = await getTheChallengeMethod();

  // Make a [Pkce] object.
  var pkce = Pkce(codeChallengeMethod, codeChallenge);

  // Call `validate`. If the client is invalid, it throws an OAuth2 exception.
  pkce.validate(codeVerifier);

  // If we reach here, we know that the `code_verifier` was valid,
  // so we can return our authorization token as per usual.
  return AuthorizationTokenResponse('...');
}
```