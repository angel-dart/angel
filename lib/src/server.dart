import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'exception.dart';
import 'response.dart';
import 'token_type.dart';

String _getParam(RequestContext req, String name, {bool body: false}) {
  var map = body == true ? req.body : req.query;
  var value = map.containsKey(name) ? map[name]?.toString() : null;

  if (value?.isNotEmpty != true)
    throw new AngelHttpException.badRequest(
        message: "Missing required parameter '$name'.");

  return value;
}

Iterable<String> _getScopes(RequestContext req, {bool body: false}) {
  var map = body == true ? req.body : req.query;
  return map['scope']?.toString()?.split(' ') ?? [];
}

abstract class Server<Client, User> {
  const Server();

  /// Finds the [Client] application associated with the given [clientId].
  FutureOr<Client> findClient(String clientId);

  Future<bool> verifyClient(Client client, String clientSecret);

  Future<String> authCodeGrant(Client client, String redirectUri, User user,
      Iterable<String> scopes, String state);

  authorize(Client client, String redirectUri, Iterable<String> scopes,
      String state, RequestContext req, ResponseContext res);

  Future<AuthorizationCodeResponse> exchangeAuthCodeForAccessToken(
      String authCode,
      String redirectUri,
      RequestContext req,
      ResponseContext res);

  Future authorizationEndpoint(RequestContext req, ResponseContext res) async {
    var responseType = _getParam(req, 'response_type');

    if (responseType != 'code')
      throw new AngelHttpException.badRequest(
          message: "Invalid response_type, expected 'code'.");

    // Ensure client ID
    var clientId = _getParam(req, 'client_id');

    // Find client
    var client = await findClient(clientId);

    if (client == null)
      throw new AuthorizationException(ErrorResponse.invalidClient);

    // Grab redirect URI
    var redirectUri = _getParam(req, 'redirect_uri');

    // Grab scopes
    var scopes = _getScopes(req);

    var state = req.query['state']?.toString() ?? '';

    return await authorize(client, redirectUri, scopes, state, req, res);
  }

  Future tokenEndpoint(RequestContext req, ResponseContext res) async {
    await req.parse();

    var grantType = _getParam(req, 'grant_type', body: true);

    if (grantType != 'authorization_code')
      throw new AngelHttpException.badRequest(
          message: "Invalid grant_type; expected 'authorization_code'.");

    var code = _getParam(req, 'code', body: true);
    var redirectUri = _getParam(req, 'redirect_uri', body: true);

    var response =
        await exchangeAuthCodeForAccessToken(code, redirectUri, req, res);
    return {'token_type': TokenType.bearer}..addAll(response.toJson());
  }

  Future handleFormSubmission(RequestContext req, ResponseContext res) async {
    await req.parse();

    // Ensure client ID
    var clientId = _getParam(req, 'client_id', body: true);

    // Find client
    var client = await findClient(clientId);

    if (client == null)
      throw new AuthorizationException(ErrorResponse.invalidClient);

    // Verify client secret
    var clientSecret = _getParam(req, 'client_secret', body: true);

    if (!await verifyClient(client, clientSecret))
      throw new AuthorizationException(ErrorResponse.invalidClient);

    // Grab redirect URI
    var redirectUri = _getParam(req, 'redirect_uri', body: true);

    // Grab scopes
    var scopes = _getScopes(req, body: true);

    var state = req.query['state']?.toString() ?? '';

    var authCode = await authCodeGrant(
        client, redirectUri, req.properties['user'], scopes, state);
    res.headers['content-type'] = 'application/x-www-form-urlencoded';
    res.write('code=' + Uri.encodeComponent(authCode));
    if (state.isNotEmpty) res.write('&state=' + Uri.encodeComponent(state));
  }
}
