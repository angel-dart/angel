library angel_framework.http.server;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'package:angel_route/angel_route.dart';
export 'package:container/container.dart';
import 'package:flatten/flatten.dart';
import 'package:json_god/json_god.dart' as god;
import 'angel_base.dart';
import 'angel_http_exception.dart';
import 'controller.dart';
import 'fatal_error.dart';
import 'hooked_service.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'routable.dart';
import 'service.dart';

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
  Router _flattened;
  bool _isProduction;
  Angel _parent;
  ServerGenerator _serverGenerator = HttpServer.bind;

  final Map _injections = {};
  final Map<dynamic, InjectionRequest> _preContained = {};
  ResponseSerializer _serializer;

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
  ///
  /// This value is memoized the first time you call it, so do not change environment
  /// configuration at runtime!
  bool get isProduction {
    if (_isProduction != null)
      return _isProduction;
    else
      return _isProduction = Platform.environment['ANGEL_ENV'] == 'production';
  }

  /// The function used to bind this instance to an HTTP server.
  ServerGenerator get serverGenerator => _serverGenerator;

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

  /// Plug-ins to be called right before server shutdown
  ///
  /// If the server is never [close]d, they will never be called.
  final List<AngelConfigurer> justBeforeStop = [];

  /// Always run before responses are sent.
  ///
  /// These will only not run if an [AngelFatalError] occurs,
  /// or if a response's `willCloseItself` is set to `true`.
  final List<RequestHandler> responseFinalizers = [];

  /// The handler currently configured to run on [AngelHttpException]s.
  AngelErrorHandler errorHandler =
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

    optimizeForProduction();
    return httpServer..listen(handleRequest);
  }

  @override
  Route addRoute(String method, String path, Object handler,
      {List middleware: const []}) {
    if (_flattened != null) {
      print(
          'WARNING: You added a route ($method $path) to the router, after it had been optimized.');
      print('This route will be ignored, and no requests will ever reach it.');
    }

    return super.addRoute(method, path, handler, middleware: middleware ?? []);
  }

  @override
  mount(Pattern path, Router router, {bool hooked: true, String namespace}) {
    if (_flattened != null) {
      print(
          'WARNING: You added mounted a child router ($path) on the router, after it had been optimized.');
      print('This route will be ignored, and no requests will ever reach it.');
    }
    return super
        .mount(path, router, hooked: hooked != false, namespace: namespace);
  }

  /// Loads some base dependencies into the service container.
  void bootstrapContainer() {
    if (runtimeType != Angel) container.singleton(this, as: Angel);
    container.singleton(this, as: AngelBase);
    container.singleton(this, as: Routable);
    container.singleton(this, as: Router);
    container.singleton(this);
  }

  /// Shuts down the server, and closes any open [StreamController]s.
  Future<HttpServer> close() async {
    HttpServer server;

    if (httpServer != null) {
      server = httpServer;
      await httpServer.close(force: true);
    }

    _afterProcessed.close();
    _beforeProcessed.close();
    _fatalErrorStream.close();
    _onController.close();

    await Future.forEach(services.keys, (Service service) async {
      if (service is HookedService) {
        await service.close();
      }
    });

    for (var plugin in justBeforeStop) await plugin(this);

    return server;
  }

  @override
  void dumpTree(
      {callback(String tree),
      String header: 'Dumping route tree:',
      String tab: '  ',
      bool showMatchers: false}) {
    if (isProduction) {
      if (_flattened == null) _flattened = flatten(this);

      _flattened.dumpTree(
          callback: callback,
          header: header?.isNotEmpty == true
              ? header
              : (isProduction
                  ? 'Dumping flattened route tree:'
                  : 'Dumping route tree:'),
          tab: tab ?? '  ',
          showMatchers: showMatchers == true);
    } else {
      super.dumpTree(
          callback: callback,
          header: header?.isNotEmpty == true
              ? header
              : (isProduction
                  ? 'Dumping flattened route tree:'
                  : 'Dumping route tree:'),
          tab: tab ?? '  ',
          showMatchers: showMatchers == true);
    }
  }

  /// Shortcut for adding a middleware to inject a key/value pair on every request.
  void inject(key, value) {
    _injections[key] = value;
  }

  /// Shortcut for adding a middleware to inject a serialize on every request.
  void injectSerializer(ResponseSerializer serializer) {
    _serializer = serializer;
  }

  Future getHandlerResult(
      handler, RequestContext req, ResponseContext res) async {
    if (handler is RequestMiddleware) {
      var result = await handler(req, res);

      if (result is RequestHandler)
        return await getHandlerResult(result, req, res);
      else
        return result;
    }

    if (handler is RequestHandler) {
      var result = await handler(req, res);
      if (result is RequestHandler)
        return await getHandlerResult(result, req, res);
      else
        return result;
    }

    if (handler is Future) {
      var result = await handler;
      if (result is RequestHandler)
        return await getHandlerResult(result, req, res);
      else
        return result;
    }

    if (handler is Function) {
      var result = await runContained(handler, req, res);
      if (result is RequestHandler)
        return await getHandlerResult(result, req, res);
      else
        return result;
    }

    if (requestMiddleware.containsKey(handler)) {
      return await getHandlerResult(requestMiddleware[handler], req, res);
    }

    return handler;
  }

  /// Runs some [handler]. Returns `true` if request execution should continue.
  Future<bool> executeHandler(
      handler, RequestContext req, ResponseContext res) async {
    var result = await getHandlerResult(handler, req, res);

    if (result is Future) {
      return await executeHandler(await result, req, res);
    } else if (result is bool) {
      return result;
    } else if (result != null) {
      res.serialize(result,
          contentType: res.headers[HttpHeaders.CONTENT_TYPE] ??
              ContentType.JSON.mimeType);
      return false;
    } else
      return res.isOpen;
  }

  Future<RequestContext> createRequestContext(HttpRequest request) {
    _beforeProcessed.add(request);
    return RequestContext.from(request, this).then((req) {
      return req..injections.addAll(_injections ?? {});
    });
  }

  Future<ResponseContext> createResponseContext(HttpResponse response) async =>
      new ResponseContext(response, this)
        ..serializer = (_serializer ?? god.serialize);

  /// Handles a single request.
  Future handleRequest(HttpRequest request) async {
    try {
      var req = await createRequestContext(request);
      var res = await createResponseContext(request.response);
      String requestedUrl = request.uri.path.replaceAll(_straySlashes, '');

      if (requestedUrl.isEmpty) requestedUrl = '/';

      Router r =
          isProduction ? (_flattened ?? (_flattened = flatten(this))) : this;
      var resolved =
          r.resolveAll(requestedUrl, requestedUrl, method: req.method);

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
                res.serialize(e.toMap(),
                    contentType: res.headers[HttpHeaders.CONTENT_TYPE] ??
                        ContentType.JSON.mimeType);
              } else {
                await errorHandler(e, req, res);
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

  /// Runs several optimizations, *if* [isProduction] is `true`.
  ///
  /// * Preprocesses all dependency injection, and eliminates the burden of reflecting handlers
  /// at run-time.
  /// * [flatten]s the route tree into a linear one.
  void optimizeForProduction() {
    if (isProduction == true) {
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

      if (_flattened == null) _flattened = flatten(this);

      _walk(_flattened);
      print('Angel is running in production mode.');
    }
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

      if (res.isOpen) res.end();

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
  @deprecated
  onError(AngelErrorHandler handler) {
    this.errorHandler = handler;
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
