# oauth2
[![Pub](https://img.shields.io/pub/v/angel_oauth2.svg)](https://pub.dartlang.org/packages/angel_oauth2)
[![build status](https://travis-ci.org/angel-dart/oauth2.svg)](https://travis-ci.org/angel-dart/oauth2)

A class containing handlers that can be used within
[Angel](https://angel-dart.github.io/) to build a spec-compliant
OAuth 2.0 server.

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  angel_oauth2: ^1.0.0
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
  final Uuid _uuid = new Uuid();

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
authorization endpoint. In most cases, you will want to show a dialog:

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
    return new AuthorizationCodeResponse('foo', refreshToken: 'bar');
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

Read the [OAuth2 specification](https://tools.ietf.org/html/rfc6749)
for in-depth information on each grant type.