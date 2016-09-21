import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:oauth2/oauth2.dart' as Oauth2;
import '../options.dart';
import '../strategy.dart';
/// Logs a user in based on an incoming OAuth access and refresh token.
typedef Future OAuth2AuthVerifier(String accessToken, String refreshToken,
    Map profile);

class OAuth2AuthStrategy extends AuthStrategy {
  @override
  String name = "oauth2";
  OAuth2AuthVerifier verifier;

  Uri authEndPoint;
  Uri tokenEndPoint;
  String clientId;
  String clientSecret;
  Uri callbackUri;
  List<String> scopes;

  @override
  Future authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions options_]) async {
    Oauth2.Client client = await makeGrant().handleAuthorizationResponse(req.query);
    // Remember: Do stuff
  }

  @override
  Future<bool> canLogout(RequestContext req, ResponseContext res) async {
    return true;
  }

  OAuth2AuthStrategy(String this.name, OAuth2AuthVerifier this.verifier,
      {Uri this.authEndPoint,
      Uri this.tokenEndPoint,
      String this.clientId,
      String this.clientSecret,
      Uri this.callbackUri,
      List<String> this.scopes: const[]}) {
    if (this.authEndPoint == null)
      throw new ArgumentError.notNull('authEndPoint');
    if (this.tokenEndPoint == null)
      throw new ArgumentError.notNull('tokenEndPoint');
    if (this.clientId == null || this.clientId.isEmpty)
      throw new ArgumentError.notNull('clientId');
  }

  call(RequestContext req, ResponseContext res) async {
    var grant = makeGrant();

    Uri to = grant.getAuthorizationUrl(callbackUri, scopes: scopes);
    return res.redirect(to.path);
  }

  Oauth2.AuthorizationCodeGrant makeGrant() {
    return new Oauth2.AuthorizationCodeGrant(
        clientId, authEndPoint, tokenEndPoint, secret: clientSecret);
  }
}

class OAuth2AuthorizationError extends AngelHttpException {
  OAuth2AuthorizationError({String message: "OAuth2 Authorization Error",
  List<String> errors: const []})
      : super.NotAuthenticated(message: message) {
    this.errors = errors;
  }
}
