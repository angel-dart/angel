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
