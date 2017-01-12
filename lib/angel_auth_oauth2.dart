library angel_auth_oauth2;

import 'dart:async';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/src/http/response_context.dart';
import 'package:angel_framework/src/http/request_context.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

/// Loads a user profile via OAuth2.
typedef Future ProfileLoader(oauth2.Client client);

final Validator OAUTH2_OPTIONS_SCHEMA = new Validator({
  'key*': isString,
  'secret*': isString,
  'authorizationEndpoint*': isString,
  'tokenEndpoint*': isString,
  'callback*': isString,
  'scopes': new isInstanceOf<Iterable<String>>()
}, defaultValues: {
  'scopes': <String>[]
}, customErrorMessages: {
  'scopes': "'scopes' must be an Iterable of strings. You provided: {{value}}"
});

class AngelAuthOauth2Options {
  String key, secret, authorizationEndpoint, tokenEndpoint, callback;
  Iterable<String> scopes;

  AngelAuthOauth2Options(
      {this.key,
      this.secret,
      this.authorizationEndpoint,
      this.tokenEndpoint,
      this.callback,
      Iterable<String> scopes: const []}) {
    this.scopes = scopes ?? [];
  }

  factory AngelAuthOauth2Options.fromJson(Map json) =>
      new AngelAuthOauth2Options(
          key: json['key'],
          secret: json['secret'],
          authorizationEndpoint: json['authorizationEndpoint'],
          tokenEndpoint: json['tokenEndpoint'],
          callback: json['callback'],
          scopes: json['scopes'] ?? <String>[]);

  Map<String, String> toJson() {
    return {
      'key': key,
      'secret': secret,
      'authorizationEndpoint': authorizationEndpoint,
      'tokenEndpoint': tokenEndpoint,
      'callback': callback,
      'scopes': scopes.toList()
    };
  }
}

class OAuth2Strategy implements AuthStrategy {
  String _name;
  AngelAuthOauth2Options _options;
  final ProfileLoader profileLoader;

  @override
  String get name => _name;

  @override
  set name(String value) => _name = name;

  /// [options] can be either a `Map` or an instance of [AngelAuthOauth2Options].
  OAuth2Strategy(this._name, options, this.profileLoader) {
    if (options is AngelAuthOauth2Options)
      _options = options;
    else if (options is Map)
      _options = new AngelAuthOauth2Options.fromJson(
          OAUTH2_OPTIONS_SCHEMA.enforce(options));
    else
      throw new ArgumentError('Invalid OAuth2 options: $options');
  }

  oauth2.AuthorizationCodeGrant createGrant() =>
      new oauth2.AuthorizationCodeGrant(
          _options.key,
          Uri.parse(_options.authorizationEndpoint),
          Uri.parse(_options.tokenEndpoint),
          secret: _options.secret);

  @override
  Future authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions options]) async {
    if (options != null) return authenticateCallback(req, res, options);

    var grant = createGrant();
    res.redirect(grant
        .getAuthorizationUrl(Uri.parse(_options.callback),
            scopes: _options.scopes)
        .toString());
    return false;
  }

  Future authenticateCallback(RequestContext req, ResponseContext res,
      [AngelAuthOptions options]) async {
    var grant = createGrant();
    await grant.getAuthorizationUrl(Uri.parse(_options.callback),
        scopes: _options.scopes);
    var client = await grant.handleAuthorizationResponse(req.query);
    return await profileLoader(client);
  }

  @override
  Future<bool> canLogout(RequestContext req, ResponseContext res) async => true;
}
