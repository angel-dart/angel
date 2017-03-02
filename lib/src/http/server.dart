library angel_framework.http.server;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'package:angel_route/angel_route.dart';
import 'angel_base.dart';
import 'angel_http_exception.dart';
import 'controller.dart';
import 'fatal_error.dart';
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

/// A function that configures an [Angel] server in some way.
typedef Future AngelConfigurer(Angel app);

/// A powerful real-time/REST/MVC server class.
class Angel extends AngelBase {
  StreamController<HttpRequest> _afterProcessed =
      new StreamController<HttpRequest>.broadcast();
  StreamController<HttpRequest> _beforeProcessed =
      new StreamController<HttpRequest>.broadcast();
  StreamController<AngelFatalError> _fatalErrorStream =
      new StreamController<AngelFatalError>.broadcast();
  StreamController<Controller> _onController =
      new StreamController<Controller>.broadcast();
  final List<Angel> _children = [];
  Angel _parent;
  ServerGenerator _serverGenerator = HttpServer.bind;

  final Map<dynamic, InjectionRequest> _preContained = {};

  /// Determines whether to allow HTTP request method overrides.
  bool allowMethodOverrides = true;

  /// Fired after a request is processed. Always runs.
  Stream<HttpRequest> get afterProcessed => _afterProcessed.stream;

  /// Fired before a request is processed. Always runs.
  Stream<HttpRequest> get beforeProcessed => _beforeProcessed.stream;

  /// All child application mounted on this instance.
  List<Angel> get children => new List<Angel>.unmodifiable(_children);

  /// Fired on fatal errors.
  Stream<AngelFatalError> get fatalErrorStream => _fatalErrorStream.stream;

  /// Indicates whether the application is running in a production environment.
  ///
  /// The criteria for this is the `ANGEL_ENV` environment variable being set to
  /// `'production'`.
  bool get isProduction => Platform.environment['ANGEL_ENV'] == 'production';

  /// Fired whenever a controller is added to this instance.
  ///
  /// **NOTE**: This is a broadcast stream.
  Stream<Controller> get onController => _onController.stream;

  /// Returns the parent instance of this application, if any.
  Angel get parent => _parent;

  /// Plug-ins to be called right before server startup.
  ///
  /// If the server is never started, they will never be called.
  final List<AngelConfigurer> justBeforeStart = [];

  /// Always run before responses are sent.
  ///
  /// These will only not run if an [AngelFatalError] occurs.
  final List<RequestHandler> responseFinalizers = [];

  /// Default error handler, show HTML error page
  AngelErrorHandler _errorHandler =
      (AngelHttpException e, req, ResponseContext res) {
    res.headers[HttpHeaders.CONTENT_TYPE] = ContentType.HTML.toString();
    res.statusCode = e.statusCode;
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
  final List before = [];

  /// [RequestMiddleware] to be run after all requests.
  final List after = [];

  /// The native HttpServer running this instancce.
  HttpServer httpServer;

  /// Handles a server error.
  _onError(e, [StackTrace st]) {
    _fatalErrorStream.add(new AngelFatalError(error: e, stack: st));
  }

  void _printDebug(x) {
    if (debug) print(x);
  }

  /// Starts the server.
  ///
  /// Returns false on failure; otherwise, returns the HttpServer.
  Future<HttpServer> startServer([InternetAddress address, int port]) async {
    var host = address ?? InternetAddress.LOOPBACK_IP_V4;
    this.httpServer = await _serverGenerator(host, port ?? 0);

    for (var configurer in justBeforeStart) {
      await configure(configurer);
    }

    preprocessRoutes();
    return httpServer..listen(handleRequest);
  }

  /// Loads some base dependencies into the service container.
  void bootstrapContainer() {
    if (runtimeType != Angel) container.singleton(this, as: Angel);
    container.singleton(this, as: AngelBase);
    container.singleton(this, as: Routable);
    container.singleton(this, as: Router);
    container.singleton(this);
  }

  /// Runs some [handler]. Returns `true` if request execution should continue.
  Future<bool> executeHandler(
      handler, RequestContext req, ResponseContext res) async {
    if (handler is RequestMiddleware) {
      var result = await handler(req, res);

      if (result is bool)
        return result == true;
      else if (result is RequestHandler)
        return await executeHandler(result, req, res);
      else if (result != null) {
        res.serialize(result,
            contentType: res.headers[HttpHeaders.CONTENT_TYPE] ??
                ContentType.JSON.mimeType);
        return false;
      } else
        return res.isOpen;
    }

    if (handler is RequestHandler) {
      var result = await handler(req, res);
      if (result is RequestHandler)
        return await executeHandler(result, req, res);
      return res.isOpen;
    }

    if (handler is Future) {
      var result = await handler;
      if (result is bool)
        return result == true;
      else if (result is RequestHandler)
        return await executeHandler(result, req, res);
      else if (result != null) {
        res.serialize(result,
            contentType: res.headers[HttpHeaders.CONTENT_TYPE] ??
                ContentType.JSON.mimeType);
        return false;
      } else
        return true;
    }

    if (handler is Function) {
      var result = await runContained(handler, req, res);
      if (result is bool)
        return result == true;
      else if (result is RequestHandler)
        return await executeHandler(result, req, res);
      else if (result != null) {
        res.serialize(result,
            contentType: res.headers[HttpHeaders.CONTENT_TYPE] ??
                ContentType.JSON.mimeType);
        return false;
      } else
        return true;
    }

    if (requestMiddleware.containsKey(handler)) {
      return await executeHandler(requestMiddleware[handler], req, res);
    }

    res.serialize(handler,
        contentType:
            res.headers[HttpHeaders.CONTENT_TYPE] ?? ContentType.JSON.mimeType);
    return false;
  }

  Future<RequestContext> createRequestContext(HttpRequest request) {
    _beforeProcessed.add(request);
    return RequestContext.from(request, this);
  }

  Future<ResponseContext> createResponseContext(HttpResponse response) async =>
      new ResponseContext(response, this);

  /// Handles a single request.
  Future handleRequest(HttpRequest request) async {
    try {
      var req = await createRequestContext(request);
      var res = await createResponseContext(request.response);
      String requestedUrl = request.uri.path.replaceAll(_straySlashes, '');

      if (requestedUrl.isEmpty) requestedUrl = '/';

      var resolved =
          resolveAll(requestedUrl, requestedUrl, method: req.method);

      for (var result in resolved) req.params.addAll(result.allParams);

      if (resolved.isNotEmpty) {
        var route = resolved.first.route;
        req.inject(Match, route.match(requestedUrl));
      }

      var m = new MiddlewarePipeline(resolved);
      req.inject(MiddlewarePipeline, m);

      var pipeline = []..addAll(before)..addAll(m.handlers)..addAll(after);

      _printDebug('Handler sequence on $requestedUrl: $pipeline');

      for (var handler in pipeline) {
        try {
          _printDebug('Executing handler: $handler');
          var result = await executeHandler(handler, req, res);
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
              res.statusCode = e.statusCode;
              List<String> accept =
                  request.headers[HttpHeaders.ACCEPT] ?? ['*/*'];
              if (accept.isEmpty ||
                  accept.contains('*/*') ||
                  accept.contains(ContentType.JSON.mimeType) ||
                  accept.contains("application/javascript")) {
                res.serialize(e.toMap());
              } else {
                await _errorHandler(e, req, res);
              }
              // _finalizeResponse(request, res);
            } catch (e, st) {
              _fatalErrorStream.add(
                  new AngelFatalError(request: request, error: e, stack: st));
            }
          } else {
            _fatalErrorStream.add(
                new AngelFatalError(request: request, error: e, stack: st));
          }

          break;
        }
      }

      try {
        await sendResponse(request, req, res);
      } catch (e, st) {
        _fatalErrorStream
            .add(new AngelFatalError(request: request, error: e, stack: st));
      }
    } catch (e, st) {
      _fatalErrorStream
          .add(new AngelFatalError(request: request, error: e, stack: st));
    }
  }

  /// Preprocesses all routes, and eliminates the burden of reflecting handlers
  /// at run-time.
  void preprocessRoutes() {
    _add(v) {
      if (v is Function && !_preContained.containsKey(v)) {
        _preContained[v] = preInject(v);
      }
    }

    void _walk(Router router) {
      if (router is Angel) {
        router..before.forEach(_add)..after.forEach(_add);
      }

      router.requestMiddleware.forEach((k, v) => _add(v));
      router.middleware.forEach(_add);
      router.routes
          .where((r) => r is SymlinkRoute)
          .map((SymlinkRoute r) => r.router)
          .forEach(_walk);
    }

    _walk(this);
  }

  /// Run a function after injecting from service container.
  /// If this function has been reflected before, then
  /// the execution will be faster, as the injection requirements were stored beforehand.
  Future runContained(
      Function handler, RequestContext req, ResponseContext res) {
    if (_preContained.containsKey(handler)) {
      return handleContained(handler, _preContained[handler])(req, res);
    }

    return runReflected(handler, req, res);
  }

  /// Runs with DI, and *always* reflects. Prefer [runContained].
  Future runReflected(
      Function handler, RequestContext req, ResponseContext res) async {
    var h =
        handleContained(handler, _preContained[handler] = preInject(handler));
    return await h(req, res);
    // return await closureMirror.apply(args).reflectee;
  }

  /// Use [sendResponse] instead.
  @deprecated
  Future sendRequest(
          HttpRequest request, RequestContext req, ResponseContext res) =>
      sendResponse(request, req, res);

  /// Sends a response.
  Future sendResponse(
      HttpRequest request, RequestContext req, ResponseContext res) async {
    _afterProcessed.add(request);

    if (!res.willCloseItself) {
      for (var finalizer in responseFinalizers) {
        await finalizer(req, res);
      }

      for (var key in res.headers.keys) {
        request.response.headers.add(key, res.headers[key]);
      }

      request.response.headers
        ..chunkedTransferEncoding = res.chunked ?? true
        ..set(HttpHeaders.CONTENT_LENGTH, res.buffer.length);

      request.response
        ..statusCode = res.statusCode
        ..cookies.addAll(res.cookies)
        ..add(res.buffer.takeBytes());
      await request.response.close();
    }
  }

  /// Applies an [AngelConfigurer] to this instance.
  Future configure(AngelConfigurer configurer) async {
    await configurer(this);

    if (configurer is Controller)
      _onController.add(controllers[configurer.findExpose().path] = configurer);
  }

  /// Starts the server, wrapped in a [runZoned] call.
  void listen({InternetAddress address, int port: 3000}) {
    runZoned(() async {
      await startServer(address, port);
    }, onError: _onError);
  }

  /// Mounts the child on this router.
  ///
  /// If the router is an [Angel] instance, all controllers
  /// will be copied, as well as services and response finalizers.
  ///
  /// [before] and [after] will be preserved.
  ///
  /// NOTE: The above will not be properly copied if [path] is
  /// a [RegExp].
  @override
  use(Pattern path, Routable routable,
      {bool hooked: true, String namespace: null}) {
    var head = path.toString().replaceAll(_straySlashes, '');

    if (routable is Angel) {
      _children.add(routable.._parent = this);
      _preContained.addAll(routable._preContained);

      if (routable.before.isNotEmpty) {
        all(path, (req, res) {
          return true;
        }, middleware: routable.before);
      }

      if (routable.after.isNotEmpty) {
        all(path, (req, res) {
          return true;
        }, middleware: routable.after);
      }

      if (routable.responseFinalizers.isNotEmpty) {
        responseFinalizers.add((req, res) async {
          if (req.path.replaceAll(_straySlashes, '').startsWith(head)) {
            for (var finalizer in routable.responseFinalizers)
              await finalizer(req, res);
          }

          return true;
        });
      }

      routable.controllers.forEach((k, v) {
        var tail = k.toString().replaceAll(_straySlashes, '');
        controllers['$head/$tail'.replaceAll(_straySlashes, '')] = v;
      });

      routable.services.forEach((k, v) {
        var tail = k.toString().replaceAll(_straySlashes, '');
        services['$head/$tail'.replaceAll(_straySlashes, '')] = v;
      });
    }

    if (routable is Service) {
      routable.app = this;
    }

    return super.use(path, routable, hooked: hooked, namespace: namespace);
  }

  /// Registers a callback to run upon errors.
  onError(AngelErrorHandler handler) {
    _errorHandler = handler;
  }

  /// Default constructor. ;)
  Angel({bool debug: false}) : super(debug: debug == true) {
    bootstrapContainer();
  }

  /// An instance mounted on a server started by the [serverGenerator].
  factory Angel.custom(ServerGenerator serverGenerator, {bool debug: false}) =>
      new Angel(debug: debug == true).._serverGenerator = serverGenerator;

  factory Angel.fromSecurityContext(SecurityContext context,
      {bool debug: false}) {
    var app = new Angel(debug: debug == true);

    app._serverGenerator = (InternetAddress address, int port) async {
      return await HttpServer.bindSecure(address, port, context);
    };

    return app;
  }

  /// Creates an HTTPS server.
  ///
  /// Provide paths to a certificate chain and server key (both .pem).
  /// If no password is provided, a random one will be generated upon running
  /// the server.
  factory Angel.secure(String certificateChainPath, String serverKeyPath,
      {bool debug: false, String password}) {
    var certificateChain =
        Platform.script.resolve(certificateChainPath).toFilePath();
    var serverKey = Platform.script.resolve(serverKeyPath).toFilePath();
    var serverContext = new SecurityContext();
    serverContext.useCertificateChain(certificateChain, password: password);
    serverContext.usePrivateKey(serverKey, password: password);

    return new Angel.fromSecurityContext(serverContext);
  }
}

/// Predetermines what needs to be injected for a handler to run.
InjectionRequest preInject(Function handler) {
  var injection = new InjectionRequest();

  ClosureMirror closureMirror = reflect(handler);

  if (closureMirror.function.parameters.isEmpty) return injection;

  // Load parameters
  for (var parameter in closureMirror.function.parameters) {
    var name = MirrorSystem.getName(parameter.simpleName);
    var type = parameter.type.reflectedType;

    if (!parameter.isNamed) {
      if (parameter.isOptional) injection.optional.add(name);

      if (type == RequestContext || type == ResponseContext) {
        injection.required.add(type);
      } else if (name == 'req') {
        injection.required.add(RequestContext);
      } else if (name == 'res') {
        injection.required.add(ResponseContext);
      } else if (type == dynamic) {
        injection.required.add(name);
      } else {
        injection.required.add([name, type]);
      }
    } else {
      injection.named[name] = type;
    }
  }

  return injection;
}
