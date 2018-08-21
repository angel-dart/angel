import 'dart:async';
import 'dart:convert';
import 'dart:io'
    show
        stderr,
        HttpRequest,
        HttpResponse,
        HttpServer,
        Platform,
        SecurityContext;

import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:angel_route/angel_route.dart';
import 'package:combinator/combinator.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:tuple/tuple.dart';

import '../core/core.dart';
import 'http_request_context.dart';
import 'http_response_context.dart';

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// Adapts `dart:io`'s [HttpServer] to serve Angel.
class AngelHttp {
  final Angel app;
  final bool useZone;
  bool _closed = false;
  HttpServer _server;
  Future<HttpServer> Function(dynamic, int) _serverGenerator = HttpServer.bind;
  StreamSubscription<HttpRequest> _sub;

  AngelHttp(this.app, {this.useZone: false});

  /// The function used to bind this instance to an HTTP server.
  Future<HttpServer> Function(dynamic, int) get serverGenerator =>
      _serverGenerator;

  /// An instance mounted on a server started by the [serverGenerator].
  factory AngelHttp.custom(
      Angel app, Future<HttpServer> Function(dynamic, int) serverGenerator,
      {bool useZone: true}) {
    return new AngelHttp(app, useZone: useZone)
      .._serverGenerator = serverGenerator;
  }

  factory AngelHttp.fromSecurityContext(Angel app, SecurityContext context,
      {bool useZone: true}) {
    var http = new AngelHttp(app, useZone: useZone);

    http._serverGenerator = (address, int port) {
      return HttpServer.bindSecure(address, port, context);
    };

    return http;
  }

  /// Creates an HTTPS server.
  ///
  /// Provide paths to a certificate chain and server key (both .pem).
  /// If no password is provided, a random one will be generated upon running
  /// the server.
  factory AngelHttp.secure(
      Angel app, String certificateChainPath, String serverKeyPath,
      {String password, bool useZone: true}) {
    var certificateChain =
        Platform.script.resolve(certificateChainPath).toFilePath();
    var serverKey = Platform.script.resolve(serverKeyPath).toFilePath();
    var serverContext = new SecurityContext();
    serverContext.useCertificateChain(certificateChain, password: password);
    serverContext.usePrivateKey(serverKey, password: password);

    return new AngelHttp.fromSecurityContext(app, serverContext,
        useZone: useZone);
  }

  /// The native HttpServer running this instance.
  HttpServer get httpServer => _server;

  /// Starts the server.
  ///
  /// Returns false on failure; otherwise, returns the HttpServer.
  Future<HttpServer> startServer([address, int port]) {
    var host = address ?? '127.0.0.1';
    return _serverGenerator(host, port ?? 0).then((server) {
      _server = server;
      return Future.wait(app.startupHooks.map(app.configure)).then((_) {
        app.optimizeForProduction();
        _sub = _server.listen(handleRequest);
        return _server;
      });
    });
  }

  /// Shuts down the underlying server.
  Future<HttpServer> close() {
    if (_closed) return new Future.value(_server);
    _closed = true;
    _sub?.cancel();
    return app.close().then((_) =>
        Future.wait(app.shutdownHooks.map(app.configure)).then((_) => _server));
  }

  /// Handles a single request.
  Future handleRequest(HttpRequest request) {
    return createRequestContext(request).then((req) {
      return createResponseContext(request.response, req).then((res) {
        handle() {
          var path = req.path;
          if (path == '/') path = '';

          Tuple3<List, Map<String, dynamic>, ParseResult<Map<String, dynamic>>>
              resolveTuple() {
            Router r = app.optimizedRouter;
            var resolved =
                r.resolveAbsolute(path, method: req.method, strip: false);

            return new Tuple3(
              new MiddlewarePipeline(resolved).handlers,
              resolved.fold<Map<String, dynamic>>(
                  <String, dynamic>{}, (out, r) => out..addAll(r.allParams)),
              resolved.isEmpty ? null : resolved.first.parseResult,
            );
          }

          var cacheKey = req.method + path;
          var tuple = app.isProduction
              ? app.handlerCache.putIfAbsent(cacheKey, resolveTuple)
              : resolveTuple();

          req.params.addAll(tuple.item2);

          req.container.registerSingleton<ParseResult<Map<String, dynamic>>>(
              tuple.item3);
          req.container.registerSingleton<ParseResult>(tuple.item3);

          if (!app.isProduction && app.logger != null) {
            req.container
                .registerSingleton<Stopwatch>(new Stopwatch()..start());
          }

          var pipeline = tuple.item1;

          Future<bool> Function() runPipeline;

          for (var handler in pipeline) {
            if (handler == null) break;

            if (runPipeline == null)
              runPipeline = () => app.executeHandler(handler, req, res);
            else {
              var current = runPipeline;
              runPipeline = () => current().then((result) => !result
                  ? new Future.value(result)
                  : app.executeHandler(handler, req, res));
            }
          }

          return runPipeline == null
              ? sendResponse(request, req, res)
              : runPipeline().then((_) => sendResponse(request, req, res));
        }

        if (useZone == false) {
          Future f;

          try {
            f = handle();
          } catch (e, st) {
            f = Future.error(e, st);
          }

          return f.catchError((e, StackTrace st) {
            if (e is FormatException)
              throw new AngelHttpException.badRequest(message: e.message)
                ..stackTrace = st;
            throw new AngelHttpException(e, stackTrace: st, statusCode: 500);
          }, test: (e) => e is! AngelHttpException).catchError(
              (ee, StackTrace st) {
            var e = ee as AngelHttpException;
            return handleAngelHttpException(
                e, e.stackTrace ?? st, req, res, request);
          }).whenComplete(() => res.dispose());
        } else {
          var zoneSpec = new ZoneSpecification(
            print: (self, parent, zone, line) {
              if (app.logger != null)
                app.logger.info(line);
              else
                parent.print(zone, line);
            },
            handleUncaughtError: (self, parent, zone, error, stackTrace) {
              var trace =
                  new Trace.from(stackTrace ?? StackTrace.current).terse;

              return new Future(() {
                AngelHttpException e;

                if (error is FormatException) {
                  e = new AngelHttpException.badRequest(message: error.message);
                } else if (error is AngelHttpException) {
                  e = error;
                } else {
                  e = new AngelHttpException(error,
                      stackTrace: stackTrace, message: error?.toString());
                }

                if (app.logger != null) {
                  app.logger.severe(e.message ?? e.toString(), error, trace);
                }

                return handleAngelHttpException(e, trace, req, res, request);
              }).catchError((e, StackTrace st) {
                var trace = new Trace.from(st ?? StackTrace.current).terse;
                request.response.close();
                // Ideally, we won't be in a position where an absolutely fatal error occurs,
                // but if so, we'll need to log it.
                if (app.logger != null) {
                  app.logger.severe(
                      'Fatal error occurred when processing ${request.uri}.',
                      e,
                      trace);
                } else {
                  stderr
                    ..writeln('Fatal error occurred when processing '
                        '${request.uri}:')
                    ..writeln(e)
                    ..writeln(trace);
                }
              });
            },
          );

          var zone = Zone.current.fork(specification: zoneSpec);
          req.container.registerSingleton<Zone>(zone);
          req.container.registerSingleton<ZoneSpecification>(zoneSpec);

          // If a synchronous error is thrown, it's not caught by `zone.run`,
          // so use a try/catch, and recover when need be.

          try {
            return zone.run(handle).whenComplete(() {
              res.dispose();
            });
          } catch (e, st) {
            zone.handleUncaughtError(e, st);
            return Future.value();
          }
        }
      });
    });
  }

  /// Handles an [AngelHttpException].
  Future handleAngelHttpException(AngelHttpException e, StackTrace st,
      RequestContext req, ResponseContext res, HttpRequest request,
      {bool ignoreFinalizers: false}) {
    if (req == null || res == null) {
      try {
        app.logger?.severe(e, st);
        request.response
          ..statusCode = 500
          ..write('500 Internal Server Error')
          ..close();
      } finally {
        return null;
      }
    }

    Future handleError;

    if (!res.isOpen)
      handleError = new Future.value();
    else {
      res.statusCode = e.statusCode;
      handleError =
          new Future.sync(() => app.errorHandler(e, req, res)).then((result) {
        return app.executeHandler(result, req, res).then((_) => res.end());
      });
    }

    return handleError.then((_) => sendResponse(request, req, res,
        ignoreFinalizers: ignoreFinalizers == true));
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

    return finalizers.then((_) {
      if (res.isOpen) res.end();

      for (var key in res.headers.keys) {
        request.response.headers.add(key, res.headers[key]);
      }

      request.response.contentLength = res.buffer.length;
      request.response.headers.chunkedTransferEncoding = res.chunked ?? true;

      List<int> outputBuffer = res.buffer.toBytes();

      if (res.encoders.isNotEmpty) {
        var allowedEncodings = req.headers
            .value('accept-encoding')
            ?.split(',')
            ?.map((s) => s.trim())
            ?.where((s) => s.isNotEmpty)
            ?.map((str) {
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
              request.response.headers.set('content-encoding', key);
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

      return request.response.close().then((_) {
        if (!app.isProduction && app.logger != null) {
          var sw = req.container.make<Stopwatch>();

          if (sw.isRunning) {
            sw?.stop();
            app.logger.info(
                "${res.statusCode} ${req.method} ${req.uri} (${sw?.elapsedMilliseconds ?? 'unknown'} ms)");
          }
        }
      });
    });
  }

  Future<HttpRequestContext> createRequestContext(HttpRequest request) {
    var path = request.uri.path.replaceAll(_straySlashes, '');
    if (path.length == 0) path = '/';
    return HttpRequestContext.from(request, app, path);
  }

  Future<ResponseContext> createResponseContext(HttpResponse response,
          [RequestContext correspondingRequest]) =>
      new Future<ResponseContext>.value(new HttpResponseContext(
          response, app, correspondingRequest as HttpRequestContext)
        ..serializer = (app.serializer ?? json.encode)
        ..encoders.addAll(app.encoders ?? {}));
}
