# angel_auth

[![Pub](https://img.shields.io/pub/v/angel_auth.svg)](https://pub.dartlang.org/packages/angel_auth)
[![build status](https://travis-ci.org/angel-dart/auth.svg?branch=master)](https://travis-ci.org/angel-dart/auth)

A complete authentication plugin for Angel. Inspired by Passport.

# Wiki
[Click here](https://github.com/angel-dart/auth/wiki).

# Bundled Strategies
* Local (with and without Basic Auth)
* Find other strategies (Twitter, Google, OAuth2, etc.) on Pub!!!

# Example
Ensure you have read the [wiki](https://github.com/angel-dart/auth/wiki).

```dart
configureServer(Angel app) async {
  var auth = AngelAuth<User>();
  auth.serializer = ...;
  auth.deserializer = ...;
  auth.strategies['local'] = LocalAuthStrategy(...);
  
  // POST route to handle username+password
  app.post('/local', auth.authenticate('local'));

  // Using Angel's asynchronous injections, we can parse the JWT
  // on demand. It won't be parsed until we check.
  app.get('/profile', ioc((User user) {
    print(user.description);
  }));
  
  // Use a comma to try multiple strategies!!!
  //
  // Each strategy is run sequentially. If one succeeds, the loop ends.
  // Authentication failures will just cause the loop to continue.
  // 
  // If the last strategy throws an authentication failure, then
  // a `401 Not Authenticated` is thrown.
  var chainedHandler = auth.authenticate(
    ['basic','facebook'],
    authOptions
  );
  
  // Apply angel_auth-specific configuration.
  await app.configure(auth.configureServer);
}
```

# Default Authentication Callback
A frequent use case within SPA's is opening OAuth login endpoints in a separate window.
[`angel_client`](https://github.com/angel-dart/client)
provides a facility for this, which works perfectly with the default callback provided
in this package.

```dart
configureServer(Angel app) async {
  var handler = auth.authenticate(
    'facebook',
    AngelAuthOptions(callback: confirmPopupAuthentication()));
  app.get('/auth/facebook', handler);
  
  // Use a comma to try multiple strategies!!!
  //
  // Each strategy is run sequentially. If one succeeds, the loop ends.
  // Authentication failures will just cause the loop to continue.
  // 
  // If the last strategy throws an authentication failure, then
  // a `401 Not Authenticated` is thrown.
  var chainedHandler = auth.authenticate(
    ['basic','facebook'],
    authOptions
  );
}
```

This renders a simple HTML page that fires the user's JWT as a `token` event in `window.opener`.
`angel_client` [exposes this as a Stream](https://github.com/angel-dart/client#authentication):

```dart
app.authenticateViaPopup('/auth/google').listen((jwt) {
  // Do something with the JWT
});
```
