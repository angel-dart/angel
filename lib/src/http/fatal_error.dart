/// Thrown whenever Angel completely fails to respond to a request.
class AngelFatalError {
  var error;
  StackTrace stack;

  AngelFatalError({this.error, this.stack});
}

