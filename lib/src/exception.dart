import 'package:angel_http_exception/angel_http_exception.dart';

class AuthorizationException extends AngelHttpException {
  final ErrorResponse errorResponse;

  AuthorizationException(this.errorResponse,
      {StackTrace stackTrace, int statusCode})
      : super(errorResponse,
            stackTrace: stackTrace, message: '', statusCode: statusCode ?? 401);
}

class ErrorResponse {
  final String code, description;

  // Taken from https://www.docusign.com/p/RESTAPIGuide/Content/OAuth2/OAuth2%20Response%20Codes.htm
  // TODO: Use original error messages
  static const ErrorResponse invalidRequest = const ErrorResponse(
          'invalid_request',
          'The request was malformed, or contains unsupported parameters.'),
      invalidClient = const ErrorResponse(
          'invalid_client', 'The client authentication failed.'),
      invalidGrant = const ErrorResponse(
          'invalid_grant', 'The provided authorization is invalid.'),
      unauthorizedClient = const ErrorResponse('unauthorized_client',
          'The client application is not allowed to use this grant_type.'),
      unauthorizedGrantType = const ErrorResponse('unsupported_grant_type',
          'A grant_type other than “password” was used in the request.'),
      invalidScope = const ErrorResponse(
          'invalid_scope', 'One or more of the scopes you provided was invalid.'),
      unsupportedTokenType = const ErrorResponse('unsupported_token_type',
          'The client tried to revoke an access token on a server not supporting this feature.'),
      invalidToken = const ErrorResponse(
          'invalid_token', 'The presented token is invalid.');

  const ErrorResponse(this.code, this.description);
}
