library angel_auth_oauth2;

import 'dart:async';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:http_parser/http_parser.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

final Validator OAUTH2_OPTIONS_SCHEMA = new Validator({
  'key*': isString,
  'secret*': isString,
  'authorizationEndpoint*': anyOf(isString, const isInstanceOf<Uri>()),
  'tokenEndpoint*': anyOf(isString, const isInstanceOf<Uri>()),
  'callback*': isString,
  'scopes': const isInstanceOf<Iterable<String>>()
}, defaultValues: {
  'scopes': <String>[]
}, customErrorMessages: {
  'scopes': "'scopes' must be an Iterable of strings. You provided: {{value}}"
});

/// Holds credentials and also specifies the means of authenticating users against a remote server.
class AngelAuthOAuth2Options {
  /// Your application's client key or client ID, registered with the remote server.
  final String key;

  /// Your application's client secret, registered with the remote server.
  final String secret;

  /// The remote endpoint that prompts external users for authentication credentials.
  final authorizationEndpoint;

  /// The remote endpoint that exchanges auth codes for access tokens.
  final tokenEndpoint;

  /// The callback URL that the OAuth2 server should redirect authenticated users to.
  final String callback;

  /// Used to split application scopes. Defaults to `' '`.
  final String delimiter;
  final Iterable<String> scopes;

  final Map<String, String> Function(MediaType, String) getParameters;

  const AngelAuthOAuth2Options(
      {this.key,
      this.secret,
      this.authorizationEndpoint,
      this.tokenEndpoint,
      this.callback,
      this.delimiter: ' ',
      this.scopes: const [],
      this.getParameters});

  factory AngelAuthOAuth2Options.fromJson(Map json) =>
      new AngelAuthOAuth2Options(
          key: json['key'],
          secret: json['secret'],
          authorizationEndpoint: json['authorizationEndpoint'],
          tokenEndpoint: json['tokenEndpoint'],
          callback: json['callback'],
          scopes: json['scopes'] ?? <String>[]);

  Map<String, dynamic> toJson() {
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

class OAuth2Strategy<T> implements AuthStrategy {
  final FutureOr<T> Function(oauth2.Client) verifier;
  String name;

  AngelAuthOAuth2Options _options;

  /// [options] can be either a `Map` or an instance of [AngelAuthOAuth2Options].
  OAuth2Strategy(this.name, options, this.verifier) {
    if (options is AngelAuthOAuth2Options)
      _options = options;
    else if (options is Map)
      _options = new AngelAuthOAuth2Options.fromJson(
          OAUTH2_OPTIONS_SCHEMA.enforce(options));
    else
      throw new ArgumentError('Invalid OAuth2 options: $options');
  }

  oauth2.AuthorizationCodeGrant createGrant() =>
      new oauth2.AuthorizationCodeGrant(
          _options.key,
          Uri.parse(_options.authorizationEndpoint),
          Uri.parse(_options.tokenEndpoint),
          secret: _options.secret,
          delimiter: _options.delimiter ?? ' ',
          getParameters: _options.getParameters);

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
    return await verifier(client);
  }

  @override
  Future<bool> canLogout(RequestContext req, ResponseContext res) async => true;
}
