import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_framework/http2.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:stream_channel/stream_channel.dart';

/// Creates a [shelf.Request]  analogous to the input [req].
///
/// The new request's `context` will contain [req.container] as `angel_shelf.container`, as well as
/// the provided [context], if any.
///
/// The context will also have the original request available as `angel_shelf.request`.
///
/// If you want to read the request body, you *must* set `keepRawRequestBuffers` to `true`
/// on your application instance.
Future<shelf.Request> convertRequest(RequestContext req, ResponseContext res,
    {String handlerPath, Map<String, Object> context}) async {
  var app = req.app;
  var headers = <String, String>{};
  req.headers.forEach((k, v) {
    headers[k] = v.join(',');
  });

  headers.remove(HttpHeaders.transferEncodingHeader);

  void Function(void Function(StreamChannel<List<int>>)) onHijack;
  String protocolVersion;
  Uri requestedUri;

  if (req is HttpRequestContext && res is HttpResponseContext) {
    protocolVersion = req.rawRequest.protocolVersion;
    requestedUri = req.rawRequest.requestedUri;

    onHijack = (void hijack(StreamChannel<List<int>> channel)) {
      new Future(() async {
        var rs = res.detach();
        var socket = await rs.detachSocket(writeHeaders: false);
        var ctrl = new StreamChannelController<List<int>>();
        var body = await req.parseRawRequestBuffer() ?? [];
        ctrl.local.sink.add(body ?? []);
        socket.listen(ctrl.local.sink.add,
            onError: ctrl.local.sink.addError, onDone: ctrl.local.sink.close);
        ctrl.local.stream.pipe(socket);
        hijack(ctrl.foreign);
      }).catchError((e, st) {
        app.logger?.severe('An error occurred while hijacking a shelf request',
            e, st as StackTrace);
      });
    };
  } else if (req is Http2RequestContext && res is Http2ResponseContext) {
    protocolVersion = '2.0';
    requestedUri = req.uri;

    onHijack = (void hijack(StreamChannel<List<int>> channel)) {
      new Future(() async {
        var rs = await res.detach();
        var ctrl = new StreamChannelController<List<int>>();
        var body = await req.parseRawRequestBuffer() ?? [];
        ctrl.local.sink.add(body ?? []);
        ctrl.local.stream.listen(rs.sendData, onDone: rs.terminate);
        hijack(ctrl.foreign);
      }).catchError((e, st) {
        stderr.writeln('An error occurred while hijacking a shelf request: $e');
        stderr.writeln(st);
      });
    };
  } else {
    throw new UnsupportedError(
        '`embedShelf` is only supported for HTTP and HTTP2 requests in Angel.');
  }

  var url = req.uri;

  if (p.isAbsolute(url.path)) {
    url = url.replace(path: url.path.substring(1));
  }

  return new shelf.Request(req.method, requestedUri,
      protocolVersion: protocolVersion,
      headers: headers,
      handlerPath: handlerPath,
      url: url,
      body: (await req.parseRawRequestBuffer()) ?? [],
      context: {'angel_shelf.request': req}
        ..addAll({'angel_shelf.container': req.container})
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
    shelf.Response shelfResponse, ResponseContext angelResponse) {
  angelResponse.headers.addAll(shelfResponse.headers);
  angelResponse.statusCode = shelfResponse.statusCode;
  angelResponse.properties['shelf_context'] = shelfResponse.context;
  angelResponse.properties['shelf_response'] = shelfResponse;
  return shelfResponse.read().pipe(angelResponse);
}
