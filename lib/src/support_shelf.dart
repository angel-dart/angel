import 'package:angel_framework/angel_framework.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'convert.dart';

/// Configures a server instance to natively run shelf request handlers.
///
/// To pass a context to the generated shelf request, add a Map
/// to `req.properties`, named `shelf_context`.
///
/// Two additional keys will be present in the `shelf` request context:
/// * `angel_shelf.request` - The Angel [RequestContext].
/// * `angel_shelf.response` - The Angel [ResponseContext].
AngelConfigurer supportShelf() {
  return (Angel app) async {
    app.before.add((RequestContext req, ResponseContext res) async {
      // Inject shelf.Request ;)
      req.inject(
          shelf.Request,
          await convertRequest(req,
              context: {'angel_shelf.response': res}
                ..addAll(req.properties['shelf_context'] ?? {})));

      // Override serializer to support returning shelf responses
      var oldSerializer = res.serializer;
      res.serializer = (val) {
        if (val is! shelf.Response) return oldSerializer(val);
        res.properties['shelf_response'] = val;
        return ''; // Write nothing
      };
    });

    // Merge shelf response if necessary
    app.responseFinalizers.add((RequestContext req, ResponseContext res) async {
      if (res.properties.containsKey('shelf_response')) {
        var shelfResponse = res.properties['shelf_response'] as shelf.Response;
        await mergeShelfResponse(shelfResponse, res);
      }
    });
  };
}
