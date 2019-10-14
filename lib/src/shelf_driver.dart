import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'shelf_request.dart';
import 'shelf_response.dart';

class AngelShelf extends Driver<shelf.Request, ShelfResponseContext,
    Stream<shelf.Request>, ShelfRequestContext, ShelfResponseContext> {
  final StreamController<shelf.Request> incomingRequests = StreamController();

  final FutureOr<shelf.Response> Function() notFound;

  AngelShelf(Angel app, {FutureOr<shelf.Response> Function() notFound})
      : this.notFound =
            notFound ?? (() => shelf.Response.notFound('Not Found')),
        super(app, null, useZone: false) {
    // Inject a final handler that will keep responses open, if we are using the
    // driver as a middleware.
    app.fallback((req, res) {
      if (res is ShelfResponseContext) {
        res.closeSilently();
      }
      return true;
    });
  }

  Future<Stream<shelf.Request>> close() {
    incomingRequests.close();
    return super.close();
  }

  Future<Stream<shelf.Request>> Function(dynamic, int) get serverGenerator =>
      (_, __) async => incomingRequests.stream;

  static UnsupportedError _unsupported() => UnsupportedError(
      'AngelShelf cannot mount a standalone server, or return a URI.');

  Future<shelf.Response> handler(shelf.Request request) async {
    var response = ShelfResponseContext(app);
    var result = await handleRawRequest(request, response);
    if (result is shelf.Response) {
      return result;
    } else if (!response.isOpen) {
      return response.shelfResponse;
    } else {
      // return await handler(request);
      return notFound();
    }
  }

  shelf.Handler middleware(shelf.Handler handler) {
    return (request) async {
      var response = ShelfResponseContext(app);
      var result = await handleRawRequest(request, response);
      if (result is shelf.Response) {
        return result;
      } else if (!response.isOpen) {
        return response.shelfResponse;
      } else {
        return await handler(request);
      }
    };
  }

  @override
  Future<shelf.Response> handleAngelHttpException(
      AngelHttpException e,
      StackTrace st,
      RequestContext req,
      ResponseContext res,
      shelf.Request request,
      ShelfResponseContext response,
      {bool ignoreFinalizers = false}) async {
    await super.handleAngelHttpException(e, st, req, res, request, response,
        ignoreFinalizers: ignoreFinalizers);
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
    var path = request.url.path.replaceAll(_straySlashes, '');
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
