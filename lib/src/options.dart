import 'package:angel_framework/angel_framework.dart';
import 'auth_token.dart';

typedef AngelAuthCallback(
    RequestContext req, ResponseContext res, String token);

typedef AngelAuthTokenCallback(
    RequestContext req, ResponseContext res, AuthToken token, user);

class AngelAuthOptions {
  AngelAuthCallback callback;
  AngelAuthTokenCallback tokenCallback;
  bool canRespondWithJson;
  String successRedirect;
  String failureRedirect;

  AngelAuthOptions(
      {this.callback,
      this.tokenCallback,
      this.canRespondWithJson: true,
      this.successRedirect,
      String this.failureRedirect});
}
