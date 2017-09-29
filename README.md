# auth_oauth2
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

class MyServer extends oauth2.Server<Client, User> {}
```

Then, implement the `findClient` and `verifyClient` to ensure that the
server class can not only identify a client application via a `client_id`,
but that it can also verify its identity via a `client_secret`.

```dart
class _Server extends Server<PseudoApplication, Map> {
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
Future authorize(
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

Naturally, 