import 'package:angel_framework/angel_framework.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

/// Simply passes an incoming request to a `shelf` handler.
RequestHandler embedShelf(shelf.Handler handler) {
  return (RequestContext req, ResponseContext res) async {
    res
      ..willCloseItself = true
      ..end();
    io.handleRequest(req.io, handler);
  };
}
