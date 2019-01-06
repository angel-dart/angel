library angel_auth_oauth2;

import 'dart:async';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:http_parser/http_parser.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

/// An Angel [AuthStrategy] that signs users in via a third-party service that speaks OAuth 2.0.
class OAuth2Strategy<User> implements AuthStrategy<User> {
  /// A callback that uses the third-party service to authenticate a [User].
  ///
  /// As always, return `null` if authentication fails.
  final FutureOr<User> Function(oauth2.Client, RequestContext, ResponseContext)
      verifier;

  /// A callback that is triggered when an OAuth2 error occurs (i.e. the user declines to login);
  final FutureOr<dynamic> Function(
      oauth2.AuthorizationException, RequestContext, ResponseContext) onError;

  /// The options defining how to connect to the third-party.
  final ExternalAuthOptions options;

  /// The URL to query to receive an authentication code.
  final Uri authorizationEndpoint;

  /// The URL to query to exchange an authentication code for a token.
  final Uri tokenEndpoint;

  /// An optional callback used to parse the response from a server who does not follow the OAuth 2.0 spec.
  final Map<String, dynamic> Function(MediaType, String) getParameters;

  /// An optional delimiter used to send requests to server who does not follow the OAuth 2.0 spec.
  final String delimiter;

  Uri _redirect;

  OAuth2Strategy(this.options, this.authorizationEndpoint, this.tokenEndpoint,
      this.verifier, this.onError,
      {this.getParameters, this.delimiter = ' '});

  oauth2.AuthorizationCodeGrant _createGrant() =>
      new oauth2.AuthorizationCodeGrant(options.clientId, authorizationEndpoint,
          tokenEndpoint,
          secret: options.clientSecret,
          delimiter: delimiter,
          getParameters: getParameters);

  @override
  FutureOr<User> authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions<User> options]) async {
    if (options != null) {
      var result = await authenticateCallback(req, res, options);
      if (result is User)
        return result;
      else
        return null;
    }

    if (_redirect == null) {
      var grant = _createGrant();
      _redirect = grant.getAuthorizationUrl(
        this.options.redirectUri,
        scopes: this.options.scopes,
      );
    }

    res.redirect(_redirect);
    return null;
  }

  /// The endpoint that is invoked by the third-party after successful authentication.
  Future<dynamic> authenticateCallback(RequestContext req, ResponseContext res,
      [AngelAuthOptions options]) async {
    var grant = _createGrant();
    grant.getAuthorizationUrl(this.options.redirectUri,
        scopes: this.options.scopes);

    try {
      var client =
          await grant.handleAuthorizationResponse(req.uri.queryParameters);
      return await verifier(client, req, res);
    } on oauth2.AuthorizationException catch (e) {
      return await onError(e, req, res);
    }
  }
}
