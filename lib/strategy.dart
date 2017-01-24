import 'dart:async';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';

abstract class Oauth2ServerStrategy extends AuthStrategy {
  @override
  final String name = 'oauth2-server';

  @override
  Future<bool> canLogout(RequestContext req, ResponseContext res) async => true;

  /// Convey to the user that one or more fields are missing.
  ///
  /// [field] can be a single value, or an `Iterable`.
  AngelHttpException missingField(field) {
    Iterable<String> fields =
        field is Iterable ? field.map((x) => x.toString()) : [field.toString()];

    if (field == null)
      throw new ArgumentError.notNull('field');
    else if (fields.isEmpty)
      throw new ArgumentError(
          'Cannot provide an empty list of missing fields.');

    return new AngelHttpException.badRequest(
        message:
            "Missing one or more of the following fields: " + fields.join(','));
  }

  /// Returns a map containing the given values of all [required] keys,
  /// or throws a [missingField] error if any are missing.
  Map<String, String> ensureAll(RequestContext req, Iterable<String> required) {
    if (required.any((str) =>
        !req.body.containsKey(str) ||
        (req.body[str] is! String && req.body[str].isEmpty)))
      throw missingField(required);

    return required
        .fold(<String, String>{}, (map, key) => map..[key] = req.query[key]);
  }

  @override
  Future authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions options]) {
    if (req.body['response_type'] is! String) {
      return new Future.error(missingField('response_type'));
    } else {
      String responseType = req.body['response_type'];

      switch (responseType) {
        case 'code':
          return authorizationCodeGrant(req, res);
        case 'authorization_code':
          return accessTokenRequest(req, res);
        default:
          throw new AngelHttpException.badRequest(
              message: "Unsupported grant type '$responseType'.");
      }
    }
  }

  /// Generates an authorization code for a client who is requesting access.
  Future<String> createAuthorizationCode(
      String clientId, String redirectUri, String scope, String state);

  /// Generates a redirect URL for a client who is requesting access via
  /// an authorization code grant request.
  ///
  /// Do not include a query component, or trailing slashes.
  Future<String> createRedirectUrl(
      String clientId, String redirectUri, String scope, String state);

  /// Performs an authorization code grant.
  Future authorizationCodeGrant(RequestContext req, ResponseContext res) async {
    var data = ensureAll(req, ['client_id']);
    String clientId = data['client_id'];
    String redirectUri = req.body['redirect_uri'],
        scope = req.body['scope'],
        state = req.body['state'];
    var redirect = await createRedirectUrl(clientId, redirectUri?.toString(),
        scope?.toString(), state?.toString());

    var code = await createAuthorizationCode(clientId, redirectUri?.toString(),
        scope?.toString(), state?.toString());

    List<String> query = ['code=' + Uri.encodeQueryComponent(code)];

    if (state?.isNotEmpty == true)
      query.add('state=' + Uri.encodeQueryComponent(state));

    res.redirect(redirect + '?' + query.join('&'));

    // TODO: Support error responses: https://tools.ietf.org/html/rfc6749#section-4
  }

  /// Awards an access token to a successfully authenticated user.
  Future<AccessTokenInfo> accessTokenRequest(
      RequestContext req, ResponseContext res) async {
    var data = ensureAll(req, ['code', 'redirect_uri', 'client_id']);
    String code = data['code'],
        redirectUri = data['redirect_uri'],
        clientId = data['client_id'];
  }
}
