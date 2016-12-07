import 'package:angel_framework/angel_framework.dart';
import 'auth_token.dart';

typedef AngelAuthCallback(
    RequestContext req, ResponseContext res, AuthToken token);

class AngelAuthOptions {
  AngelAuthCallback callback;
  bool canRespondWithJson;
  String successRedirect;
  String failureRedirect;

  AngelAuthOptions(
      {this.callback,
      this.canRespondWithJson: true,
      this.successRedirect,
      String this.failureRedirect});
}
