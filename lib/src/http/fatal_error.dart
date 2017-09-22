import 'dart:async';
import 'dart:io';

/// Thrown whenever Angel completely fails to respond to a request.
class AngelFatalError {
  var error;
  HttpRequest request;
  StackTrace stack;
  Zone zone;

  AngelFatalError({this.request, this.error, this.stack, this.zone});
}

