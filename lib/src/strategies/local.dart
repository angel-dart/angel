import 'dart:async';
import 'package:dart2_constant/convert.dart';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import '../options.dart';
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
  final bool allowBasic;
  final bool forceBasic;
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
            new String.fromCharCodes(base64.decode(base64AuthString));
        if (_rgxUsrPass.hasMatch(authString)) {
          Match usrPassMatch = _rgxUsrPass.firstMatch(authString);
          verificationResult =
              await verifier(usrPassMatch.group(1), usrPassMatch.group(2));
        } else
          throw new AngelHttpException.badRequest(errors: [invalidMessage]);

        if (verificationResult == false || verificationResult == null) {
          res
            ..statusCode = 401
            ..headers[HttpHeaders.WWW_AUTHENTICATE] = 'Basic realm="$realm"'
            ..end();
          return false;
        }

        res.properties['user'] = verificationResult;
        return true;
      }
    }

    if (verificationResult == null) {
      await req.parse();
      if (_validateString(req.body[usernameField]?.toString()) &&
          _validateString(req.body[passwordField]?.toString())) {
        verificationResult =
            await verifier(req.body[usernameField]?.toString(), req.body[passwordField]?.toString());
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
          ..statusCode = 401
          ..headers[HttpHeaders.WWW_AUTHENTICATE] = 'Basic realm="$realm"'
          ..end();
      }

      return false;
    } else if (verificationResult != null && verificationResult != false) {
      return verificationResult;
    } else {
      throw new AngelHttpException.notAuthenticated();
    }
  }
}
