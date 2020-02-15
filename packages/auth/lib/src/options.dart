import 'dart:async';

import 'package:angel_framework/angel_framework.dart';
import 'auth_token.dart';

typedef FutureOr AngelAuthCallback(
    RequestContext req, ResponseContext res, String token);

typedef FutureOr AngelAuthTokenCallback<User>(
    RequestContext req, ResponseContext res, AuthToken token, User user);

class AngelAuthOptions<User> {
  AngelAuthCallback callback;
  AngelAuthTokenCallback<User> tokenCallback;
  String successRedirect;
  String failureRedirect;

  /// If `false` (default: `true`), then successful authentication will return `true` and allow the
  /// execution of subsequent handlers, just like any other middleware.
  ///
  /// Works well with `Basic` authentication.
  bool canRespondWithJson;

  AngelAuthOptions(
      {this.callback,
      this.tokenCallback,
      this.canRespondWithJson = true,
      this.successRedirect,
      String this.failureRedirect});
}
