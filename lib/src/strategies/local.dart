import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import '../options.dart';
import '../plugin.dart';
import '../strategy.dart';

bool _validateString(String str) => str != null && str.isNotEmpty;

/// Determines the validity of an incoming username and password.
typedef Future LocalAuthVerifier(String username, String password);

class LocalAuthStrategy extends AuthStrategy {
  RegExp _rgxBasic = new RegExp(r'^Basic (.+)$', caseSensitive: false);
  RegExp _rgxUsrPass = new RegExp(r'^([^:]+):(.+)$');

  @override
  String name = 'local';
  LocalAuthVerifier verifier;
  String usernameField;
  String passwordField;
  String invalidMessage;
  bool allowBasic;
  bool forceBasic;
  String realm;

  LocalAuthStrategy(LocalAuthVerifier this.verifier,
      {String this.usernameField: 'username',
      String this.passwordField: 'password',
      String this.invalidMessage:
          'Please provide a valid username and password.',
      bool this.allowBasic: true,
      bool this.forceBasic: false,
      String this.realm: 'Authentication is required.'}) {}

  @override
  Future<bool> canLogout(RequestContext req, ResponseContext res) async {
    return true;
  }

  @override
  Future authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions options_]) async {
    AngelAuthOptions options = options_ ?? new AngelAuthOptions();
    var verificationResult;

    if (allowBasic) {
      String authHeader = req.headers.value(HttpHeaders.AUTHORIZATION) ?? "";
      if (_rgxBasic.hasMatch(authHeader)) {
        String base64AuthString = _rgxBasic.firstMatch(authHeader).group(1);
        String authString =
            new String.fromCharCodes(BASE64.decode(base64AuthString));
        if (_rgxUsrPass.hasMatch(authString)) {
          Match usrPassMatch = _rgxUsrPass.firstMatch(authString);
          verificationResult =
              await verifier(usrPassMatch.group(1), usrPassMatch.group(2));
        } else
          throw new AngelHttpException.BadRequest(errors: [invalidMessage]);
      }
    }

    if (verificationResult == null) {
      if (_validateString(req.body[usernameField]) &&
          _validateString(req.body[passwordField])) {
        verificationResult =
            await verifier(req.body[usernameField], req.body[passwordField]);
      }
    }

    if (verificationResult == false || verificationResult == null) {
      if (options.failureRedirect != null &&
          options.failureRedirect.isNotEmpty) {
        res.redirect(options.failureRedirect, code: HttpStatus.UNAUTHORIZED);
        return false;
      }

      if (forceBasic) {
        res
          ..status(401)
          ..header(HttpHeaders.WWW_AUTHENTICATE, 'Basic realm="$realm"')
          ..end();
        return false;
      } else
        return false;
    } else if (verificationResult != null && verificationResult != false) {
      return verificationResult;
    } else {
      throw new AngelHttpException.NotAuthenticated();
    }
  }
}
