import 'package:angel_http_exception/angel_http_exception.dart';

/// An Angel-friendly wrapper around OAuth2 [ErrorResponse] instances.
class AuthorizationException extends AngelHttpException {
  final ErrorResponse errorResponse;

  AuthorizationException(this.errorResponse,
      {StackTrace stackTrace, int statusCode, error})
      : super(error ?? errorResponse,
            stackTrace: stackTrace, message: '', statusCode: statusCode ?? 400);

  @override
  Map toJson() {
    var m = {
      'error': errorResponse.code,
      'error_description': errorResponse.description,
    };

    if (errorResponse.uri != null)
      m['error_uri'] = errorResponse.uri.toString();

    return m;
  }
}

/// Represents an OAuth2 authentication error.
class ErrorResponse {
  /// The request is missing a required parameter, includes an invalid parameter value, includes a parameter more than once, or is otherwise malformed.
  static const String invalidRequest = 'invalid_request';

  /// The `code_verifier` given by the client does not match the expected value.
  static const String invalidGrant = 'invalid_grant';

  /// The client is not authorized to request an authorization code using this method.
  static const String unauthorizedClient = 'unauthorized_client';

  /// The resource owner or authorization server denied the request.
  static const String accessDenied = 'access_denied';

  /// The authorization server does not support obtaining an authorization code using this method.
  static const String unsupportedResponseType = 'unsupported_response_type';

  /// The requested scope is invalid, unknown, or malformed.
  static const String invalidScope = 'invalid_scope';

  /// The authorization server encountered an unexpected condition that prevented it from fulfilling the request.
  static const String serverError = 'server_error';

  /// The authorization server is currently unable to handle the request due to a temporary overloading or maintenance of the server.
  static const String temporarilyUnavailable = 'temporarily_unavailable';

  /// The authorization request is still pending as the end user hasn't
  /// yet completed the user interaction steps (Section 3.3).  The
  /// client SHOULD repeat the Access Token Request to the token
  /// endpoint (a process known as polling).  Before each request
  /// the client MUST wait at least the number of seconds specified by
  /// the "interval" parameter of the Device Authorization Response (see
  /// Section 3.2), or 5 seconds if none was provided, and respect any
  /// increase in the polling interval required by the "slow_down"
  /// error.
  static const String authorizationPending = 'authorization_pending';

  /// A variant of "authorization_pending", the authorization request is
  /// still pending and polling should continue, but the interval MUST
  /// be increased by 5 seconds for this and all subsequent requests.
  static const String slowDown = 'slow_down';

  /// The "device_code" has expired and the device flow authorization
  /// session has concluded.  The client MAY commence a Device
  /// Authorization Request but SHOULD wait for user interaction before
  /// restarting to avoid unnecessary polling.
  static const String expiredToken = 'expired_token';

  /// A short string representing the error.
  final String code;

  /// A relatively detailed description of the source of the error.
  final String description;

  /// An optional [Uri] directing users to more information about the error.
  final Uri uri;

  /// The exact value received from the client, if a "state" parameter was present in the client authorization request.
  final String state;

  const ErrorResponse(this.code, this.description, this.state, {this.uri});

  @override
  String toString() => 'OAuth2 error ($code): $description';
}
