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
import 'route.dart';
import 'service.dart';
export 'package:container/container.dart';

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
  var _onController = new StreamController<Controller>.broadcast();
  ServerGenerator _serverGenerator =
      (address, port) async => await HttpServer.bind(address, port);

  /// Fired after a request is processed. Always runs.
  Stream<HttpRequest> get afterProcessed => _afterProcessed.stream;

  /// Fired before a request is processed. Always runs.
  Stream<HttpRequest> get beforeProcessed => _beforeProcessed.stream;


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

  /// [RequestMiddleware] to be run before all requests.
  List before = [];

  /// [RequestMiddleware] to be run after all requests.
  List after = [];

  /// The native HttpServer running this instancce.
  HttpServer httpServer;

  /// Starts the server.
  ///
  /// Returns false on failure; otherwise, returns the HttpServer.
  Future<HttpServer> startServer([InternetAddress address, int port]) async {
    var server =
        await _serverGenerator(address ?? InternetAddress.LOOPBACK_IP_V4, port ?? 0);
    this.httpServer = server;

    server.listen(handleRequest);

    return server;
  }

  /// Loads some base dependencies into the service container.
  void bootstrapContainer() {
    container.singleton(this, as: AngelBase);
    container.singleton(this);

    if (runtimeType != Angel)
      container.singleton(this, as: Angel);
  }

  Future handleRequest(HttpRequest request) async {
    _beforeProcessed.add(request);

    String requestedUrl = request.uri
        .toString()
        .replaceAll("?" + request.uri.query, "")
        .replaceAll(new RegExp(r'\/+$'), '');

    if (requestedUrl.isEmpty) requestedUrl = '/';

    RequestContext req = await RequestContext.from(request, {}, this, null);
    ResponseContext res = await ResponseContext.from(request.response, this);

    bool canContinue = true;

    executeHandler(handler, req) async {
      if (canContinue) {
        try {
          canContinue = await _applyHandler(handler, req, res);
        } catch (e, stackTrace) {
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
            } catch (_) {}
          }
          _onError(e, stackTrace);
          canContinue = false;
          return false;
        }
      } else
        return false;
    }

    for (var handler in before) {
      await executeHandler(handler, req);
    }

    for (Route route in routes) {
      if (!canContinue) break;

      if (route.matcher.hasMatch(requestedUrl) &&
          (request.method == route.method || route.method == '*')) {
        req.params = route.parseParameters(requestedUrl);
        req.route = route;

        for (var handler in route.handlers) {
          await executeHandler(handler, req);
        }
      }
    }

    for (var handler in after) {
      await executeHandler(handler, req);
    }

    _finalizeResponse(request, res);
  }

  Future<bool> _applyHandler(
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
      var result = await handler(req.underlyingRequest);
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
      return await _applyHandler(requestMiddleware[handler], req, res);
    }

    res.willCloseItself = true;
    res.underlyingResponse.write(god.serialize(handler));
    await res.underlyingResponse.close();
    return false;
  }

  _finalizeResponse(HttpRequest request, ResponseContext res) async {
    try {
      if (!res.willCloseItself) {
        res.responseData.forEach((blob) => request.response.add(blob));
        await request.response.close();
        _afterProcessed.add(request);
      }
    } catch (e) {
      failSilently(request, res);
    }
  }

  String _randomString(int length) {
    var rand = new Random();
    var codeUnits = new List.generate(length, (index) {
      return rand.nextInt(33) + 89;
    });

    return new String.fromCharCodes(codeUnits);
  }

  // Run a function after injecting from service container
  Future runContained(Function handler, RequestContext req, ResponseContext res, {Map<String, dynamic> namedParameters, Map<Type, dynamic> injecting}) async {
    ClosureMirror closureMirror = reflect(handler);
    List args = [];

    for (ParameterMirror parameter in closureMirror.function.parameters) {
      if (parameter.type.reflectedType == RequestContext)
        args.add(req);
      else if (parameter.type.reflectedType == ResponseContext)
        args.add(res);
      else {
        // First, search to see if we can map this to a type
        if (parameter.type.reflectedType != dynamic) {
          args.add(container.make(parameter.type.reflectedType, namedParameters: namedParameters, injecting: injecting));
        } else {
          String name = MirrorSystem.getName(parameter.simpleName);

          if (name == "req")
            args.add(req);
          else if (name == "res")
            args.add(res);
          else if (req.params.containsKey(name))
            args.add(req.params[name]);
          else {
            throw new Exception("Cannot resolve parameter '$name' within handler.");
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
      {bool hooked: true, String middlewareNamespace: null}) {
    if (routable is Service) {
      routable.app = this;
    }
    return super.use(path, routable,
        hooked: hooked, middlewareNamespace: middlewareNamespace);
  }

  /// Registers a callback to run upon errors.
  onError(AngelErrorHandler handler) {
    _errorHandler = handler;
  }

  /// Handles a server error.
  _onError(e, [StackTrace stackTrace]) {
    stderr.write(e.toString());
    if (stackTrace != null) stderr.write(stackTrace.toString());
  }

  Angel() : super() {
    bootstrapContainer();
  }

  /// Creates an HTTPS server.
  /// Provide paths to a certificate chain and server key (both .pem).
  /// If no password is provided, a random one will be generated upon running
  /// the server.
  Angel.secure(String certificateChainPath, String serverKeyPath,
      {String password})
      : super() {
    bootstrapContainer();
    _serverGenerator = (InternetAddress address, int port) async {
      var certificateChain =
          Platform.script.resolve('server_chain.pem').toFilePath();
      var serverKey = Platform.script.resolve('server_key.pem').toFilePath();
      var serverContext = new SecurityContext();
      serverContext.useCertificateChain(certificateChain);
      serverContext.usePrivateKey(serverKey,
          password: password ?? _randomString(8));

      return await HttpServer.bindSecure(address, port, serverContext);
    };
  }
}
