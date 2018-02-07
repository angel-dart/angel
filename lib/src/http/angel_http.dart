import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:angel_route/angel_route.dart';
import 'package:combinator/combinator.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:pool/pool.dart';
import 'package:tuple/tuple.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'server.dart';

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// Adapts `dart:io`'s [HttpServer] to serve Angel.
class AngelHttp {
  final Angel app;

  Pool _pool;

  AngelHttp(this.app);

  /// Handles a single request.
  Future handleRequest(HttpRequest request) async {
    var req = await createRequestContext(request);
    var res = await createResponseContext(request.response, req);

    try {
      var path = req.path;
      if (path == '/') path = '';

      Tuple3<List, Map, ParseResult<Map<String, String>>> resolveTuple() {
        Router r = _flattened ?? this;
        var resolved =
        r.resolveAbsolute(path, method: req.method, strip: false);

        return new Tuple3(
          new MiddlewarePipeline(resolved).handlers,
          resolved.fold<Map>({}, (out, r) => out..addAll(r.allParams)),
          resolved.isEmpty ? null : resolved.first.parseResult,
        );
      }

      var cacheKey = req.method + path;
      var tuple = app.isProduction
          ? app.handlerCache.putIfAbsent(cacheKey, resolveTuple)
          : resolveTuple();

      //req.inject(Zone, zone);
      //req.inject(ZoneSpecification, zoneSpec);
      req.params.addAll(tuple.item2);
      req.inject(ParseResult, tuple.item3);

      if (app.logger != null) req.inject(Stopwatch, new Stopwatch()..start());

      var pipeline = tuple.item1;

      for (var handler in pipeline) {
        try {
          if (handler == null || !await app.executeHandler(handler, req, res))
            break;
        } on AngelHttpException catch (e, st) {
          e.stackTrace ??= st;
          return await handleAngelHttpException(e, st, req, res, request);
        }
      }

      try {
        await sendResponse(request, req, res);
      } on AngelHttpException catch (e, st) {
        e.stackTrace ??= st;
        return await handleAngelHttpException(
          e,
          st,
          req,
          res,
          request,
          ignoreFinalizers: true,
        );
      }
    } on FormatException catch (error, stackTrace) {
      var e = new AngelHttpException.badRequest(message: error.message);

      if (app.logger != null) {
        app.logger.severe(e.message ?? e.toString(), error, stackTrace);
      }

      return await handleAngelHttpException(e, stackTrace, req, res, request);
    } catch (error, stackTrace) {
      var e = new AngelHttpException(error,
          stackTrace: stackTrace, message: error?.toString());

      if (app.logger != null) {
        app.logger.severe(e.message ?? e.toString(), error, stackTrace);
      }

      return await handleAngelHttpException(e, stackTrace, req, res, request);
    } finally {
      res.dispose();
    }
  }

  /// Handles an [AngelHttpException].
  Future handleAngelHttpException(AngelHttpException e, StackTrace st,
      RequestContext req, ResponseContext res, HttpRequest request,
      {bool ignoreFinalizers: false}) async {
    if (req == null || res == null) {
      try {
        app.logger?.severe(e, st);
        request.response
          ..statusCode = HttpStatus.INTERNAL_SERVER_ERROR
          ..write('500 Internal Server Error')
          ..close();
      } finally {
        return null;
      }
    }

    if (res.isOpen) {
      res.statusCode = e.statusCode;
      var result = await app.errorHandler(e, req, res);
      await app.executeHandler(result, req, res);
      res.end();
    }

    return await sendResponse(request, req, res,
        ignoreFinalizers: ignoreFinalizers == true);
  }

  /// Sends a response.
  Future sendResponse(
      HttpRequest request, RequestContext req, ResponseContext res,
      {bool ignoreFinalizers: false}) {
    if (res.willCloseItself) return new Future.value();

    Future finalizers = ignoreFinalizers == true
        ? new Future.value()
        : app.responseFinalizers.fold<Future>(
        new Future.value(), (out, f) => out.then((_) => f(req, res)));

    if (res.isOpen) res.end();

    for (var key in res.headers.keys) {
      request.response.headers.add(key, res.headers[key]);
    }

    request.response.contentLength = res.buffer.length;
    request.response.headers.chunkedTransferEncoding = res.chunked ?? true;

    List<int> outputBuffer = res.buffer.toBytes();

    if (res.encoders.isNotEmpty) {
      var allowedEncodings =
      req.headers[HttpHeaders.ACCEPT_ENCODING]?.map((str) {
        // Ignore quality specifications in accept-encoding
        // ex. gzip;q=0.8
        if (!str.contains(';')) return str;
        return str.split(';')[0];
      });

      if (allowedEncodings != null) {
        for (var encodingName in allowedEncodings) {
          Converter<List<int>, List<int>> encoder;
          String key = encodingName;

          if (res.encoders.containsKey(encodingName))
            encoder = res.encoders[encodingName];
          else if (encodingName == '*') {
            encoder = res.encoders[key = res.encoders.keys.first];
          }

          if (encoder != null) {
            request.response.headers.set(HttpHeaders.CONTENT_ENCODING, key);
            outputBuffer = res.encoders[key].convert(outputBuffer);
            request.response.contentLength = outputBuffer.length;
            break;
          }
        }
      }
    }

    request.response
      ..statusCode = res.statusCode
      ..cookies.addAll(res.cookies)
      ..add(outputBuffer);

    return finalizers.then((_) async {
      request.response.close();

      if (req.injections.containsKey(PoolResource)) {
        req.injections[PoolResource].release();
      }

      if (app.logger != null) {
        var sw = req.grab<Stopwatch>(Stopwatch);

        if (sw.isRunning) {
          sw?.stop();
          app.logger.info("${res.statusCode} ${req.method} ${req.uri} (${sw
              ?.elapsedMilliseconds ?? 'unknown'} ms)");
        }
      }
    });
  }

  Future<RequestContext> createRequestContext(HttpRequest request) {
    var path = request.uri.path.replaceAll(_straySlashes, '');
    if (path.length == 0) path = '/';
    return RequestContext.from(request, app, path).then((req) async {
      if (_pool != null) req.inject(PoolResource, await _pool.request());
      if (app.injections.isNotEmpty) app.injections.forEach(req.inject);
      return req;
    });
  }

  Future<ResponseContext> createResponseContext(HttpResponse response,
      [RequestContext correspondingRequest]) =>
      new Future<ResponseContext>.value(
          new ResponseContext(response, app, correspondingRequest)
            ..serializer = (_serializer ?? god.serialize)
            ..encoders.addAll(app.encoders ?? {}));

  /// Limits the maximum number of requests to be handled concurrently by this instance.
  ///
  /// You can optionally provide a [timeout] to limit the amount of time a request can be
  /// handled before.
  void throttle(int maxConcurrentRequests, {Duration timeout}) {
    _pool = new Pool(maxConcurrentRequests, timeout: timeout);
  }
}