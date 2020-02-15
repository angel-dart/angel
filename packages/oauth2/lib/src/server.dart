import 'dart:async';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'exception.dart';
import 'pkce.dart';
import 'response.dart';
import 'token_type.dart';

/// A request handler that performs an arbitrary authorization token grant.
typedef FutureOr<AuthorizationTokenResponse> ExtensionGrant(
    RequestContext req, ResponseContext res);

Future<String> _getParam(RequestContext req, String name, String state,
    {bool body = false, bool throwIfEmpty = true}) async {
  Map<String, dynamic> data;

  if (body == true) {
    data = await req.parseBody().then((_) => req.bodyAsMap);
  } else {
    data = req.queryParameters;
  }

  var value = data.containsKey(name) ? data[name]?.toString() : null;

  if (value?.isNotEmpty != true && throwIfEmpty) {
    throw AuthorizationException(
      ErrorResponse(
        ErrorResponse.invalidRequest,
        'Missing required parameter "$name".',
        state,
      ),
      statusCode: 400,
    );
  }

  return value;
}

Future<Iterable<String>> _getScopes(RequestContext req,
    {bool body = false}) async {
  Map<String, dynamic> data;

  if (body == true) {
    data = await req.parseBody().then((_) => req.bodyAsMap);
  } else {
    data = req.queryParameters;
  }

  return data['scope']?.toString()?.split(' ') ?? [];
}

/// An OAuth2 authorization server, which issues access tokens to third parties.
abstract class AuthorizationServer<Client, User> {
  const AuthorizationServer();

  static const String _internalServerError =
      'An internal server error occurred.';

  /// A [Map] of custom authorization token grants. Use this to handle custom grant types, perhaps even your own.
  Map<String, ExtensionGrant> get extensionGrants => {};

  /// Finds the [Client] application associated with the given [clientId].
  FutureOr<Client> findClient(String clientId);

  /// Verify that a [client] is the one identified by the [clientSecret].
  FutureOr<bool> verifyClient(Client client, String clientSecret);

  /// Retrieves the PKCE `code_verifier` parameter from a [RequestContext], or throws.
  Future<String> getPkceCodeVerifier(RequestContext req,
      {bool body = true, String state, Uri uri}) async {
    var data = body
        ? await req.parseBody().then((_) => req.bodyAsMap)
        : req.queryParameters;
    var codeVerifier = data['code_verifier'];

    if (codeVerifier == null) {
      throw AuthorizationException(ErrorResponse(ErrorResponse.invalidRequest,
          "Missing `code_verifier` parameter.", state,
          uri: uri));
    } else if (codeVerifier is! String) {
      throw AuthorizationException(ErrorResponse(ErrorResponse.invalidRequest,
          "The `code_verifier` parameter must be a string.", state,
          uri: uri));
    } else {
      return codeVerifier as String;
    }
  }

  /// Prompt the currently logged-in user to grant or deny access to the [client].
  ///
  /// In many applications, this will entail showing a dialog to the user in question.
  ///
  /// If [implicit] is `true`, then the client is requesting an *implicit grant*.
  /// Be aware of the security implications of this - do not handle them exactly
  /// the same.
  FutureOr<void> requestAuthorizationCode(
      Client client,
      String redirectUri,
      Iterable<String> scopes,
      String state,
      RequestContext req,
      ResponseContext res,
      bool implicit) {
    throw AuthorizationException(
      ErrorResponse(
        ErrorResponse.unsupportedResponseType,
        'Authorization code grants are not supported.',
        state,
      ),
      statusCode: 400,
    );
  }

  /// Exchanges an authorization code for an authorization token.
  FutureOr<AuthorizationTokenResponse> exchangeAuthorizationCodeForToken(
      Client client,
      String authCode,
      String redirectUri,
      RequestContext req,
      ResponseContext res) {
    throw AuthorizationException(
      ErrorResponse(
        ErrorResponse.unsupportedResponseType,
        'Authorization code grants are not supported.',
        req.uri.queryParameters['state'] ?? '',
      ),
      statusCode: 400,
    );
  }

  /// Refresh an authorization token.
  FutureOr<AuthorizationTokenResponse> refreshAuthorizationToken(
      Client client,
      String refreshToken,
      Iterable<String> scopes,
      RequestContext req,
      ResponseContext res) async {
    var body = await req.parseBody().then((_) => req.bodyAsMap);
    throw AuthorizationException(
      ErrorResponse(
        ErrorResponse.unsupportedResponseType,
        'Refreshing authorization tokens is not supported.',
        body['state']?.toString() ?? '',
      ),
      statusCode: 400,
    );
  }

  /// Issue an authorization token to a user after authenticating them via [username] and [password].
  FutureOr<AuthorizationTokenResponse> resourceOwnerPasswordCredentialsGrant(
      Client client,
      String username,
      String password,
      Iterable<String> scopes,
      RequestContext req,
      ResponseContext res) async {
    var body = await req.parseBody().then((_) => req.bodyAsMap);
    throw AuthorizationException(
      ErrorResponse(
        ErrorResponse.unsupportedResponseType,
        'Resource owner password credentials grants are not supported.',
        body['state']?.toString() ?? '',
      ),
      statusCode: 400,
    );
  }

  /// Performs a client credentials grant. Only use this in situations where the client is 100% trusted.
  FutureOr<AuthorizationTokenResponse> clientCredentialsGrant(
      Client client, RequestContext req, ResponseContext res) async {
    var body = await req.parseBody().then((_) => req.bodyAsMap);
    throw AuthorizationException(
      ErrorResponse(
        ErrorResponse.unsupportedResponseType,
        'Client credentials grants are not supported.',
        body['state']?.toString() ?? '',
      ),
      statusCode: 400,
    );
  }

  /// Performs a device code grant.
  FutureOr<DeviceCodeResponse> requestDeviceCode(Client client,
      Iterable<String> scopes, RequestContext req, ResponseContext res) async {
    var body = await req.parseBody().then((_) => req.bodyAsMap);
    throw AuthorizationException(
      ErrorResponse(
        ErrorResponse.unsupportedResponseType,
        'Device code grants are not supported.',
        body['state']?.toString() ?? '',
      ),
      statusCode: 400,
    );
  }

  /// Produces an authorization token from a given device code.
  FutureOr<AuthorizationTokenResponse> exchangeDeviceCodeForToken(
      Client client,
      String deviceCode,
      String state,
      RequestContext req,
      ResponseContext res) async {
    var body = await req.parseBody().then((_) => req.bodyAsMap);
    throw AuthorizationException(
      ErrorResponse(
        ErrorResponse.unsupportedResponseType,
        'Device code grants are not supported.',
        body['state']?.toString() ?? '',
      ),
      statusCode: 400,
    );
  }

  /// Returns the [Uri] that a client can be redirected to in the case of an implicit grant.
  Uri completeImplicitGrant(AuthorizationTokenResponse token, Uri redirectUri,
      {String state}) {
    var queryParameters = <String, String>{};

    queryParameters.addAll({
      'access_token': token.accessToken,
      'token_type': 'bearer',
    });

    if (state != null) queryParameters['state'] = state;

    if (token.expiresIn != null)
      queryParameters['expires_in'] = token.expiresIn.toString();

    if (token.scope != null) queryParameters['scope'] = token.scope.join(' ');

    var fragment =
        queryParameters.keys.fold<StringBuffer>(StringBuffer(), (buf, k) {
      if (buf.isNotEmpty) buf.write('&');
      return buf
        ..write(
          '$k=' + Uri.encodeComponent(queryParameters[k]),
        );
    }).toString();

    return redirectUri.replace(fragment: fragment);
  }

  /// A request handler that invokes the correct logic, depending on which type
  /// of grant the client is requesting.
  Future<void> authorizationEndpoint(
      RequestContext req, ResponseContext res) async {
    String state = '';

    try {
      var query = req.queryParameters;
      state = query['state']?.toString() ?? '';
      var responseType = await _getParam(req, 'response_type', state);

      req.container.registerLazySingleton<Pkce>((_) {
        return Pkce.fromJson(req.queryParameters, state: state);
      });

      if (responseType == 'code' || responseType == 'token') {
        // Ensure client ID
        var clientId = await _getParam(req, 'client_id', state);

        // Find client
        var client = await findClient(clientId);

        if (client == null) {
          throw AuthorizationException(ErrorResponse(
            ErrorResponse.unauthorizedClient,
            'Unknown client "$clientId".',
            state,
          ));
        }

        // Grab redirect URI
        var redirectUri = await _getParam(req, 'redirect_uri', state);

        // Grab scopes
        var scopes = await _getScopes(req);

        return await requestAuthorizationCode(client, redirectUri, scopes,
            state, req, res, responseType == 'token');
      }

      throw AuthorizationException(
          ErrorResponse(
            ErrorResponse.invalidRequest,
            'Invalid or no "response_type" parameter provided',
            state,
          ),
          statusCode: 400);
    } on AngelHttpException {
      rethrow;
    } catch (e, st) {
      throw AuthorizationException(
        ErrorResponse(
          ErrorResponse.serverError,
          _internalServerError,
          state,
        ),
        error: e,
        statusCode: 500,
        stackTrace: st,
      );
    }
  }

  static final RegExp _rgxBasic = RegExp(r'Basic ([^$]+)');
  static final RegExp _rgxBasicAuth = RegExp(r'([^:]*):([^$]*)');

  /// A request handler that either exchanges authorization codes for authorization tokens,
  /// or refreshes authorization tokens.
  Future tokenEndpoint(RequestContext req, ResponseContext res) async {
    String state = '';
    Client client;

    try {
      AuthorizationTokenResponse response;
      var body = await req.parseBody().then((_) => req.bodyAsMap);

      state = body['state']?.toString() ?? '';

      req.container.registerLazySingleton<Pkce>((_) {
        return Pkce.fromJson(req.bodyAsMap, state: state);
      });

      var grantType = await _getParam(req, 'grant_type', state,
          body: true, throwIfEmpty: false);

      if (grantType != 'urn:ietf:params:oauth:grant-type:device_code' &&
          grantType != null) {
        var match =
            _rgxBasic.firstMatch(req.headers.value('authorization') ?? '');

        if (match != null) {
          match = _rgxBasicAuth
              .firstMatch(String.fromCharCodes(base64Url.decode(match[1])));
        }

        if (match == null) {
          throw AuthorizationException(
            ErrorResponse(
              ErrorResponse.unauthorizedClient,
              'Invalid or no "Authorization" header.',
              state,
            ),
            statusCode: 400,
          );
        } else {
          var clientId = match[1], clientSecret = match[2];
          client = await findClient(clientId);

          if (client == null) {
            throw AuthorizationException(
              ErrorResponse(
                ErrorResponse.unauthorizedClient,
                'Invalid "client_id" parameter.',
                state,
              ),
              statusCode: 400,
            );
          }

          if (!await verifyClient(client, clientSecret)) {
            throw AuthorizationException(
              ErrorResponse(
                ErrorResponse.unauthorizedClient,
                'Invalid "client_secret" parameter.',
                state,
              ),
              statusCode: 400,
            );
          }
        }
      }

      if (grantType == 'authorization_code') {
        var code = await _getParam(req, 'code', state, body: true);
        var redirectUri =
            await _getParam(req, 'redirect_uri', state, body: true);
        response = await exchangeAuthorizationCodeForToken(
            client, code, redirectUri, req, res);
      } else if (grantType == 'refresh_token') {
        var refreshToken =
            await _getParam(req, 'refresh_token', state, body: true);
        var scopes = await _getScopes(req);
        response = await refreshAuthorizationToken(
            client, refreshToken, scopes, req, res);
      } else if (grantType == 'password') {
        var username = await _getParam(req, 'username', state, body: true);
        var password = await _getParam(req, 'password', state, body: true);
        var scopes = await _getScopes(req);
        response = await resourceOwnerPasswordCredentialsGrant(
            client, username, password, scopes, req, res);
      } else if (grantType == 'client_credentials') {
        response = await clientCredentialsGrant(client, req, res);

        if (response.refreshToken != null) {
          // Remove refresh token
          response = AuthorizationTokenResponse(
            response.accessToken,
            expiresIn: response.expiresIn,
            scope: response.scope,
          );
        }
      } else if (extensionGrants.containsKey(grantType)) {
        response = await extensionGrants[grantType](req, res);
      } else if (grantType == null) {
        // This is a device code grant.
        var clientId = await _getParam(req, 'client_id', state, body: true);
        client = await findClient(clientId);

        if (client == null) {
          throw AuthorizationException(
            ErrorResponse(
              ErrorResponse.unauthorizedClient,
              'Invalid "client_id" parameter.',
              state,
            ),
            statusCode: 400,
          );
        }

        var scopes = await _getScopes(req, body: true);
        var deviceCodeResponse =
            await requestDeviceCode(client, scopes, req, res);
        return deviceCodeResponse.toJson();
      } else if (grantType == 'urn:ietf:params:oauth:grant-type:device_code') {
        var clientId = await _getParam(req, 'client_id', state, body: true);
        client = await findClient(clientId);

        if (client == null) {
          throw AuthorizationException(
            ErrorResponse(
              ErrorResponse.unauthorizedClient,
              'Invalid "client_id" parameter.',
              state,
            ),
            statusCode: 400,
          );
        }

        var deviceCode = await _getParam(req, 'device_code', state, body: true);
        response = await exchangeDeviceCodeForToken(
            client, deviceCode, state, req, res);
      }

      if (response != null) {
        return <String, dynamic>{'token_type': AuthorizationTokenType.bearer}
          ..addAll(response.toJson());
      }

      throw AuthorizationException(
        ErrorResponse(
          ErrorResponse.invalidRequest,
          'Invalid or no "grant_type" parameter provided',
          state,
        ),
        statusCode: 400,
      );
    } on AngelHttpException {
      rethrow;
    } catch (e, st) {
      throw AuthorizationException(
        ErrorResponse(
          ErrorResponse.serverError,
          _internalServerError,
          state,
        ),
        error: e,
        statusCode: 500,
        stackTrace: st,
      );
    }
  }
}
