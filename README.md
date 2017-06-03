# auth_oauth2

[![version 1.0.1](https://img.shields.io/badge/pub-1.0.1-brightgreen.svg)](https://pub.dartlang.org/packages/angel_auth_oauth2)

`package:angel_auth` strategy for OAuth2 login, i.e. Facebook or Github.

# Usage
First, create an options object:

```dart
configureServer(Angel app) async {
  // Load from a Map, i.e. app config:
  var opts = new AngelOAuth2Options.fromJson(map);
  
  // Create in-place:
  const AngelAuthOAuth2Options OAUTH2_CONFIG = const AngelAuthOAuth2Options(
      callback: '<callback-url>',
      key: '<client-id>',
      secret: '<client-secret>',
      authorizationEndpoint: '<authorization-endpoint>',
      tokenEndpoint: '<access-token-endpoint>');
}
```

After getting authenticated against the remote server, we need to be able to identify
users within our own application. Use an `OAuth2Verifier` to associate remote users
with local users.

```dart
/// You might use a pure function to create a verifier that queries a
/// given service.
OAuth2Verifier oauth2verifier(Service userService) {
  return (oauth2.Client client) async {
     var response = await client.get('https://api.github.com/user');
     var ghUser = JSON.decode(response.body);
     var id = ghUser['id'];
 
     Iterable<Map> matchingUsers = await userService.index({
       'query': {'githubId': id}
     });
 
     if (matchingUsers.isNotEmpty) {
       // Return the corresponding user, if it exists
       return User.parse(matchingUsers.firstWhere((u) => u['githubId'] == id));
     } else {
       // Otherwise,create a user
       return await userService.create({'githubId': id}).then(User.parse);
     }
   };
}
```

Now, initialize an `OAuth2Strategy`, using the options and verifier.
You'll also need to provide a name for this instance of the strategy.
Consider using the name of the remote authentication provider (ex. `facebook`).

```dart
configureServer(Angel app) {
  // ...
  var oauthStrategy =
    new OAuth2Strategy('github', OAUTH2_CONFIG, oauth2Verifier(app.service('users')));
}
```

Lastly, connect it to an `AngelAuth` instance, and wire it up to an `Angel` server.
Set up two routes:
  1. Redirect users to the external provider
  2. Acts as a callback and handles an access code
  
In the case of the callback route, you may want to display an HTML page that closes
a popup window. In this case, use `confirmPopupAuthentication`, which is bundled with
`package:angel_auth`, as a `callback` function:

```dart
configureServer(Angel app) async {
  // ...
  var auth = new AngelAuth();
  auth.strategies.add(oauth2Strategy);
  
  // Redirect
  app.get('/auth/github', auth.authenticate('github'));
  
  // Callback
  app.get('/auth/github/callback', auth.authenticate(
    'github',
    new AngelAuthOptions(callback: confirmPopupAuthentication())
  ));
  
  // Connect the plug-in!!!
  await app.configure(auth);
}
```

## Custom Scope Delimiter
This package should work out-of-the-box for most OAuth2 providers, such as Github or Dropbox.
However, if your OAuth2 scopes are separated by a delimiter other than the default (`' '`),
you can add it in the `AngelOAuth2Options` constructor:

```dart
configureServer(Angel app) async {
  const AngelOAuth2Options OPTS = const AngelOAuth2Options(
    // ...
    delimiter: ','
  );
}
```