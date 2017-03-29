# angel_auth

[![version 1.0.2](https://img.shields.io/badge/version-1.0.2-brightgreen.svg)](https://pub.dartlang.org/packages/angel_auth)
![build status](https://travis-ci.org/angel-dart/auth.svg?branch=master)

A complete authentication plugin for Angel. Inspired by Passport.

# Documentation
[Click here](https://github.com/angel-dart/auth/wiki).

# Supported Strategies
* Local (with and without Basic Auth)

# Default Authentication Callback
A frequent use case within SPA's is opening OAuth login endpoints in a separate window.
[`angel_client`](https://github.com/angel-dart/client)
provides a facility for this, which works perfectly with the default callback provided
in this package.

```dart
app.authenticate('facebook', new AngelAuthOptions(callback: confirmPopupAuthentication()));
```
