import 'dart:io';

/// Thrown whenever Angel completely fails to respond to a request.
class AngelFatalError {
  var error;
  HttpRequest request;
  StackTrace stack;

  AngelFatalError({this.request, this.error, this.stack});
}

