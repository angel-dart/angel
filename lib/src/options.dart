import 'package:angel_framework/angel_framework.dart';

typedef AngelAuthCallback(
    RequestContext req, ResponseContext res, String token);

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
