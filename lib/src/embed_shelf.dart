import 'package:angel_framework/angel_framework.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'convert.dart';

/// Simply passes an incoming request to a `shelf` handler.
///
/// If the handler does not return a [shelf.Response], then the
/// result will be passed down the Angel middleware pipeline, like with
/// any other request handler.
///
/// If [throwOnNullResponse] is `true` (default: `false`), then a 500 error will be thrown
/// if the [handler] returns `null`.
RequestHandler embedShelf(shelf.Handler handler,
    {String handlerPath,
    Map<String, Object> context,
    bool throwOnNullResponse = false}) {
  return (RequestContext req, ResponseContext res) async {
    var shelfRequest = await convertRequest(req, res,
        handlerPath: handlerPath, context: context);
    try {
      var result = await handler(shelfRequest);
      if (result is! shelf.Response && result != null) return result;
      if (result == null && throwOnNullResponse == true) {
        throw AngelHttpException('Internal Server Error');
      }
      await mergeShelfResponse(result, res);
      return false;
    } on shelf.HijackException {
      // On hijack, do nothing, because the hijack handlers already call res.detach();
      return null;
    } catch (e) {
      rethrow;
    }
  };
}
