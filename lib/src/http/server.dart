library angel_framework.http.server;

import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;
import 'dart:mirrors';
import 'package:json_god/json_god.dart' as god;
import 'angel_base.dart';
import 'angel_http_exception.dart';
import 'controller.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'routable.dart';
import 'service.dart';
export 'package:container/container.dart';

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// A function that binds an [Angel] server to an Internet address and port.
typedef Future<HttpServer> ServerGenerator(InternetAddress address, int port);

/// Handles an [AngelHttpException].
typedef Future AngelErrorHandler(
    AngelHttpException err, RequestContext req, ResponseContext res);

/// A function that configures an [AngelBase] server in some way.
typedef Future AngelConfigurer(AngelBase app);

/// A powerful real-time/REST/MVC server class.
class Angel extends AngelBase {
  var _afterProcessed = new StreamController<HttpRequest>.broadcast();
  var _beforeProcessed = new StreamController<HttpRequest>.broadcast();
  var _fatalErrorStream = new StreamController<Map>.broadcast();
  var _onController = new StreamController<Controller>.broadcast();
  final Random _rand = new Random.secure();
  ServerGenerator _serverGenerator =
      (address, port) async => await HttpServer.bind(address, port);

  /// Fired after a request is processed. Always runs.
  Stream<HttpRequest> get afterProcessed => _afterProcessed.stream;

  /// Fired before a request is processed. Always runs.
  Stream<HttpRequest> get beforeProcessed => _beforeProcessed.stream;

  /// Fired on fatal errors.
  Stream<Map> get fatalErrorStream => _fatalErrorStream.stream;

  /// Fired whenever a controller is added to this instance.
  ///
  /// **NOTE**: This is a broadcast stream.
  Stream<Controller> get onController => _onController.stream;

  /// Default error handler, show HTML error page
  AngelErrorHandler _errorHandler =
      (AngelHttpException e, req, ResponseContext res) {
    res.header(HttpHeaders.CONTENT_TYPE, ContentType.HTML.toString());
    res.status(e.statusCode);
    res.write("<!DOCTYPE html><html><head><title>${e.message}</title>");
    res.write("</head><body><h1>${e.message}</h1><ul>");
    for (String error in e.errors) {
      res.write("<li>$error</li>");
    }
    res.write("</ul></body></html>");
    res.end();
  };

  /// The handler currently configured to run on [AngelHttpException]s.
  AngelErrorHandler get errorHandler => _errorHandler;

  /// [RequestMiddleware] to be run before all requests.
  List before = [];

  /// [RequestMiddleware] to be run after all requests.
  List after = [];

  /// The native HttpServer running this instancce.
  HttpServer httpServer;

  /// Handles a server error.
  _onError(e, [StackTrace stackTrace]) {
    _fatalErrorStream.add({"error": e, "stack": stackTrace});
  }

  void _printDebug(x) {
    if (debug) print(x);
  }

  String _randomString(int length) {
    var codeUnits = new List.generate(length, (index) {
      return _rand.nextInt(33) + 89;
    });

    return new String.fromCharCodes(codeUnits);
  }

  /// Starts the server.
  ///
  /// Returns false on failure; otherwise, returns the HttpServer.
  Future<HttpServer> startServer([InternetAddress address, int port]) async {
    final host = address ?? InternetAddress.LOOPBACK_IP_V4;
    this.httpServer = await _serverGenerator(host, port ?? 0);
    return httpServer..listen(handleRequest);
  }

  /// Loads some base dependencies into the service container.
  void bootstrapContainer() {
    container.singleton(this, as: AngelBase);
    container.singleton(this, as: Routable);
    container.singleton(this, as: Router);
    container.singleton(this);

    if (runtimeType != Angel) container.singleton(this, as: Angel);
  }

  Future<bool> executeHandler(
      handler, RequestContext req, ResponseContext res) async {
    if (handler is RequestMiddleware) {
      var result = await handler(req, res);

      if (result is bool)
        return result == true;
      else if (result != null) {
        res.json(result);
        return false;
      } else
        return res.isOpen;
    }

    if (handler is RequestHandler) {
      await handler(req, res);
      return res.isOpen;
    }

    if (handler is RawRequestHandler) {
      var result = await handler(req.io);
      if (result is bool)
        return result == true;
      else if (result != null) {
        res.json(result);
        return false;
      } else
        return true;
    }

    if (handler is Future) {
      var result = await handler;
      if (result is bool)
        return result == true;
      else if (result != null) {
        res.json(result);
        return false;
      } else
        return true;
    }

    if (handler is Function) {
      var result = await runContained(handler, req, res);
      if (result is bool)
        return result == true;
      else if (result != null) {
        res.json(result);
        return false;
      } else
        return true;
    }

    if (requestMiddleware.containsKey(handler)) {
      return await executeHandler(requestMiddleware[handler], req, res);
    }

    res.willCloseItself = true;
    res.io.write(god.serialize(handler));
    await res.io.close();
    return false;
  }

  Future handleRequest(HttpRequest request) async {
    _beforeProcessed.add(request);

    final req = await RequestContext.from(request, this);
    final res = new ResponseContext(request.response, this);
    String requestedUrl = request.uri.path.replaceAll(_straySlashes, '');

    if (requestedUrl.isEmpty) requestedUrl = '/';

    final resolved = [];

    if (requestedUrl == '/') {
      resolved.add(root.indexRoute);
    } else {
      resolved.addAll(resolveAll(requestedUrl, method: request.method));
      final route = resolved.first;
      req.params.addAll(route?.parseParameters(requestedUrl) ?? {});
      req.inject(Match, route.match(requestedUrl));
    }

    final pipeline = []..addAll(before);

    if (resolved.isNotEmpty) {
      for (final route in resolved) {
        pipeline.addAll(route.handlerSequence);
      }
    }

    pipeline.addAll(after);

    _printDebug('Handler sequence on $requestedUrl: $pipeline');

    for (final handler in pipeline) {
      try {
        _printDebug('Executing handler: $handler');
        final result = await executeHandler(handler, req, res);
        _printDebug('Result: $result');

        if (!result) {
          _printDebug('Last executed handler: $handler');
          break;
        } else {
          _printDebug(
              'Handler completed successfully, did not terminate response: $handler');
        }
      } catch (e, st) {
        _printDebug('Caught error in handler $handler: $e');
        _printDebug(st);

        if (e is AngelHttpException) {
          // Special handling for AngelHttpExceptions :)
          try {
            res.status(e.statusCode);
            String accept = request.headers.value(HttpHeaders.ACCEPT);
            if (accept == "*/*" ||
                accept.contains(ContentType.JSON.mimeType) ||
                accept.contains("application/javascript")) {
              res.json(e.toMap());
            } else {
              await _errorHandler(e, req, res);
            }
            _finalizeResponse(request, res);
          } catch (_) {
            // Todo: This exception needs to be caught as well.
          }
        } else {
          // Todo: Uncaught exceptions need to be... Caught.
        }

        _onError(e, st);
        break;
      }
    }

    try {
      _afterProcessed.add(request);

      if (!res.willCloseItself) {
        request.response.add(res.buffer.takeBytes());
        await request.response.close();
      }
    } catch (e) {
      failSilently(request, res);
    }
  }

  // Run a function after injecting from service container
  Future runContained(Function handler, RequestContext req, ResponseContext res,
      {Map<String, dynamic> namedParameters}) async {
    ClosureMirror closureMirror = reflect(handler);
    List args = [];

    for (ParameterMirror parameter in closureMirror.function.parameters) {
      if (parameter.type.reflectedType == RequestContext)
        args.add(req);
      else if (parameter.type.reflectedType == ResponseContext)
        args.add(res);
      else {
        // First, search to see if we can map this to a type
        if (req.injections.containsKey(parameter.type.reflectedType)) {
          args.add(req.injections[parameter.type.reflectedType]);
          continue;
        } else {
          String name = MirrorSystem.getName(parameter.simpleName);

          if (req.params.containsKey(name))
            args.add(req.params[name]);
          else if (name == "req")
            args.add(req);
          else if (name == "res")
            args.add(res);
          else if (req.injections.containsKey(name))
            args.add(req.injections[name]);
          else if (parameter.type.reflectedType != dynamic) {
            args.add(container.make(parameter.type.reflectedType,
                injecting: req.injections));
          } else {
            throw new Exception(
                "Cannot resolve parameter '$name' within handler.");
          }
        }
      }
    }

    return await closureMirror.apply(args).reflectee;
  }

  /// Applies an [AngelConfigurer] to this instance.
  Future configure(AngelConfigurer configurer) async {
    await configurer(this);

    if (configurer is Controller) _onController.add(configurer);
  }

  /// Fallback when an error is thrown while handling a request.
  void failSilently(HttpRequest request, ResponseContext res) {}

  /// Starts the server.
  void listen({InternetAddress address, int port: 3000}) {
    runZoned(() async {
      await startServer(address, port);
    }, onError: _onError);
  }

  @override
  use(Pattern path, Routable routable,
      {bool hooked: true, String namespace: null}) {
    if (routable is Service) {
      routable.app = this;
    }

    return super.use(path, routable, hooked: hooked, namespace: namespace);
  }

  /// Registers a callback to run upon errors.
  onError(AngelErrorHandler handler) {
    _errorHandler = handler;
  }

  Angel({bool debug: false}) : super(debug: debug) {
    bootstrapContainer();
  }

  /// Creates an HTTPS server.
  /// Provide paths to a certificate chain and server key (both .pem).
  /// If no password is provided, a random one will be generated upon running
  /// the server.
  factory Angel.secure(String certificateChainPath, String serverKeyPath,
      {bool debug: false, String password}) {
    final app = new Angel(debug: debug);

    app._serverGenerator = (InternetAddress address, int port) async {
      var certificateChain =
          Platform.script.resolve(certificateChainPath).toFilePath();
      var serverKey = Platform.script.resolve(serverKeyPath).toFilePath();
      var serverContext = new SecurityContext();
      serverContext.useCertificateChain(certificateChain);
      serverContext.usePrivateKey(serverKey,
          password: password ?? app._randomString(8));

      return await HttpServer.bindSecure(address, port, serverContext);
    };

    return app;
  }
}
