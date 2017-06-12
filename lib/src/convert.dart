import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:shelf/shelf.dart' as shelf;

/// Creates a [shelf.Request]  analogous to the input [request].
///
/// The new request's `context` will contain [request.properties] as `angel_shelf.properties`, as well as
/// the provided [context], if any.
///
/// The context will also have the original request available as `angel_shelf.request`.
///
/// If you want to read the request body, you *must* `storeOriginalBuffer` to `true`
/// on your application instance.
Future<shelf.Request> convertRequest(RequestContext request,
    {String handlerPath, Map<String, Object> context}) async {
  var headers = <String, String>{};
  request.headers.forEach((k, v) {
    headers[k] = v.join(',');
  });

  headers.remove(HttpHeaders.TRANSFER_ENCODING);

  void onHijack(
      void hijack(Stream<List<int>> stream, StreamSink<List<int>> sink)) {
    request.io.response.detachSocket(writeHeaders: false).then((socket) {
      return request.lazyOriginalBuffer().then((buf) {
        var ctrl = new StreamController<List<int>>()..add(buf ?? []);
        socket.listen(ctrl.add, onError: ctrl.addError, onDone: ctrl.close);
        hijack(socket, socket);
      });
    }).catchError((e, st) {
      stderr.writeln('An error occurred while hijacking a shelf request: $e');
      stderr.writeln(st);
    });
  }

  return new shelf.Request(request.method, request.io.requestedUri,
      protocolVersion: request.io.protocolVersion,
      headers: headers,
      handlerPath: handlerPath,
      url: new Uri(
          path: request.io.requestedUri.path.substring(1),
          query: request.io.requestedUri.query),
      body: (await request.lazyOriginalBuffer()) ?? [],
      context: {'angel_shelf.request': request}
        ..addAll({'angel_shelf.properties': request.properties})
        ..addAll(context ?? {}),
      onHijack: onHijack);
}

/// Applies the state of the [shelfResponse] into the [angelResponse].
///
/// Merges all headers, sets the status code, and writes the body.
///
/// In addition, the response's context will be available in `angelResponse.properties`
/// as `shelf_context`.
Future mergeShelfResponse(
    shelf.Response shelfResponse, ResponseContext angelResponse) async {
  angelResponse.headers.addAll(shelfResponse.headers);
  angelResponse.statusCode = shelfResponse.statusCode;
  angelResponse.properties['shelf_context'] = shelfResponse.context;
  await shelfResponse.read().forEach(angelResponse.buffer.add);
  angelResponse.end();
}
