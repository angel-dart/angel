import 'dart:async';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import '../options.dart';
import '../strategy.dart';

bool _validateString(String str) => str != null && str.isNotEmpty;

/// Determines the validity of an incoming username and password.
typedef FutureOr<User> LocalAuthVerifier<User>(
    String username, String password);

class LocalAuthStrategy<User> extends AuthStrategy<User> {
  RegExp _rgxBasic = RegExp(r'^Basic (.+)$', caseSensitive: false);
  RegExp _rgxUsrPass = RegExp(r'^([^:]+):(.+)$');

  LocalAuthVerifier<User> verifier;
  String usernameField;
  String passwordField;
  String invalidMessage;
  final bool allowBasic;
  final bool forceBasic;
  String realm;

  LocalAuthStrategy(this.verifier,
      {String this.usernameField = 'username',
      String this.passwordField = 'password',
      String this.invalidMessage =
          'Please provide a valid username and password.',
      bool this.allowBasic = true,
      bool this.forceBasic = false,
      String this.realm = 'Authentication is required.'});

  @override
  Future<User> authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions options_]) async {
    AngelAuthOptions options = options_ ?? AngelAuthOptions();
    User verificationResult;

    if (allowBasic) {
      String authHeader = req.headers.value('authorization') ?? "";

      if (_rgxBasic.hasMatch(authHeader)) {
        String base64AuthString = _rgxBasic.firstMatch(authHeader).group(1);
        String authString =
            String.fromCharCodes(base64.decode(base64AuthString));
        if (_rgxUsrPass.hasMatch(authString)) {
          Match usrPassMatch = _rgxUsrPass.firstMatch(authString);
          verificationResult =
              await verifier(usrPassMatch.group(1), usrPassMatch.group(2));
        } else
          throw AngelHttpException.badRequest(errors: [invalidMessage]);

        if (verificationResult == false || verificationResult == null) {
          res
            ..statusCode = 401
            ..headers['www-authenticate'] = 'Basic realm="$realm"';
          await res.close();
          return null;
        }

        return verificationResult;
      }
    }

    if (verificationResult == null) {
      var body = await req
          .parseBody()
          .then((_) => req.bodyAsMap)
          .catchError((_) => <String, dynamic>{});
      if (_validateString(body[usernameField]?.toString()) &&
          _validateString(body[passwordField]?.toString())) {
        verificationResult = await verifier(
            body[usernameField]?.toString(), body[passwordField]?.toString());
      }
    }

    if (verificationResult == false || verificationResult == null) {
      if (options.failureRedirect != null &&
          options.failureRedirect.isNotEmpty) {
        await res.redirect(options.failureRedirect, code: 401);
        return null;
      }

      if (forceBasic) {
        res.headers['www-authenticate'] = 'Basic realm="$realm"';
        throw AngelHttpException.notAuthenticated();
      }

      return null;
    } else if (verificationResult != null && verificationResult != false) {
      return verificationResult;
    } else {
      throw AngelHttpException.notAuthenticated();
    }
  }
}
