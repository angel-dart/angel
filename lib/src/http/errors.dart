part of angel_framework.http;

class _AngelHttpExceptionBase implements Exception {
  int statusCode;
  String message;
  List<String> errors;

  _AngelHttpExceptionBase.base() {}

  _AngelHttpExceptionBase(this.statusCode, this.message,
      {List<String> this.errors: const []});

  @override
  String toString() {
    return "$statusCode: $message";
  }

  Map toMap() {
    return {
      'isError': true,
      'statusCode': statusCode,
      'message': message,
      'errors': errors
    };
  }
}

/// Basically the same as
/// [feathers-errors](https://github.com/feathersjs/feathers-errors).
class AngelHttpException extends _AngelHttpExceptionBase {
  /// Throws a 500 Internal Server Error.
  /// Set includeRealException to true to print include the actual exception along with
  /// this error. Useful flag for development vs. production.
  AngelHttpException(Exception exception,
      {bool includeRealException: false, StackTrace stackTrace}) :super.base() {
    statusCode = 500;
    message = "500 Internal Server Error";
    if (includeRealException) {
      errors.add(exception.toString());
      if (stackTrace != null) {
        errors.add(stackTrace.toString());
      }
    }
  }

  /// Throws a 400 Bad Request error, including an optional arrray of (validation?)
  /// errors you specify.
  AngelHttpException.BadRequest(
      {String message: '400 Bad Request', List<String> errors: const[]})
      : super(400, message, errors: errors);

  /// Throws a 401 Not Authenticated error.
  AngelHttpException.NotAuthenticated({String message: '401 Not Authenticated'})
      : super(401, message);

  /// Throws a 402 Payment Required error.
  AngelHttpException.PaymentRequired({String message: '402 Payment Required'})
      : super(402, message);

  /// Throws a 403 Forbidden error.
  AngelHttpException.Forbidden({String message: '403 Forbidden'})
      : super(403, message);

  /// Throws a 404 Not Found error.
  AngelHttpException.NotFound({String message: '404 Not Found'})
      : super(404, message);

  /// Throws a 405 Method Not Allowed error.
  AngelHttpException.MethodNotAllowed(
      {String message: '405 Method Not Allowed'})
      : super(405, message);

  /// Throws a 406 Not Acceptable error.
  AngelHttpException.NotAcceptable({String message: '406 Not Acceptable'})
      : super(406, message);

  /// Throws a 408 Timeout error.
  AngelHttpException.MethodTimeout({String message: '408 Timeout'})
      : super(408, message);

  /// Throws a 409 Conflict error.
  AngelHttpException.Conflict({String message: '409 Conflict'})
      : super(409, message);

  /// Throws a 422 Not Processable error.
  AngelHttpException.NotProcessable({String message: '422 Not Processable'})
      : super(422, message);

  /// Throws a 501 Not Implemented error.
  AngelHttpException.NotImplemented({String message: '501 Not Implemented'})
      : super(501, message);

  /// Throws a 503 Unavailable error.
  AngelHttpException.Unavailable({String message: '503 Unavailable'})
      : super(503, message);
}