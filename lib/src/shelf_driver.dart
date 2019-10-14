import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'shelf_request.dart';
import 'shelf_response.dart';

class AngelShelf extends Driver<shelf.Request, ShelfResponseContext,
    Stream<shelf.Request>, ShelfRequestContext, ShelfResponseContext> {
  AngelShelf.custom(Angel app, {bool useZone = true})
      : super(app, (_, __) => throw _unsupported(), useZone: useZone);

  static UnsupportedError _unsupported() => UnsupportedError(
      'AngelShelf cannot mount a standalone server, or return a URI.');

  Future<shelf.Response> handler(shelf.Request request) async {
    var response = ShelfResponseContext(app);
    await handleRawRequest(request, response);
    return response.shelfResponse;
  }

  @override
  void addCookies(ShelfResponseContext response, Iterable<Cookie> cookies) {
    // Don't do anything here, otherwise you get duplicate cookies.
    // response.cookies.addAll(cookies);
  }

  @override
  Future closeResponse(ShelfResponseContext response) {
    return response.close();
  }

  @override
  Uri get uri => throw _unsupported();

  static final RegExp _straySlashes = RegExp(r'(^/+)|(/+$)');

  @override
  Future<ShelfRequestContext> createRequestContext(
      shelf.Request request, ShelfResponseContext response) {
    var path = uri.path.replaceAll(_straySlashes, '');
    if (path.isEmpty) path = '/';
    var rq =
        ShelfRequestContext(app, app.container.createChild(), request, path);
    return Future.value(rq);
  }

  @override
  Future<ShelfResponseContext> createResponseContext(
      shelf.Request request, ShelfResponseContext response,
      [ShelfRequestContext correspondingRequest]) {
    // Return the original response.
    return Future.value(response..correspondingRequest = correspondingRequest);
  }

  @override
  Stream<ShelfResponseContext> createResponseStreamFromRawRequest(
      shelf.Request request) {
    return Stream.fromIterable([null]);
  }

  @override
  void setChunkedEncoding(ShelfResponseContext response, bool value) {
    response.chunked = value;
  }

  @override
  void setContentLength(ShelfResponseContext response, int length) {
    response.contentLength = length;
  }

  @override
  void setHeader(ShelfResponseContext response, String key, String value) {
    response.headers[key] = value;
  }

  @override
  void setStatusCode(ShelfResponseContext response, int value) {
    response.statusCode = value;
  }

  @override
  void writeStringToResponse(ShelfResponseContext response, String value) {
    response.write(value);
  }

  @override
  void writeToResponse(ShelfResponseContext response, List<int> data) {
    response.add(data);
  }
}
