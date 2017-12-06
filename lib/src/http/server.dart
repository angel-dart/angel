library angel_framework.http.server;

import 'dart:async';
import 'dart:collection' show HashMap;
import 'dart:convert';
import 'dart:io';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:angel_route/angel_route.dart';
import 'package:combinator/combinator.dart';
export 'package:container/container.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';
import 'package:tuple/tuple.dart';
import 'angel_base.dart';
import 'controller.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'routable.dart';
import 'service.dart';

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// A function that binds an [Angel] server to an Internet address and port.
typedef Future<HttpServer> ServerGenerator(address, int port);

/// A function that configures an [Angel] server in some way.
typedef Future AngelConfigurer(Angel app);

/// A powerful real-time/REST/MVC server class.
class Angel extends AngelBase {
  final List<Angel> _children = [];
  final Map<String, Tuple3<List, Map, ParseResult<Map<String, String>>>>
      handlerCache = new HashMap();

  Router _flattened;
  bool _isProduction;
  Angel _parent;
  Pool _pool;
  StreamSubscription<HttpRequest> _sub;
  ServerGenerator _serverGenerator = HttpServer.bind;

  /// A global Map of converters that can transform responses bodies.
  final Map<String, Converter<List<int>, List<int>>> encoders = {};

  final Map _injections = {};

  /// Creates a safe zone within which a request can be handled, without crashing the application.
  Future<ZoneSpecification> Function(
          HttpRequest request, RequestContext req, ResponseContext res)
      createZoneForRequest;

  final Map<dynamic, InjectionRequest> _preContained = {};
  ResponseSerializer _serializer;

  /// A [Map] of dependency data obtained via reflection.
  ///
  /// You may modify this [Map] yourself if you intend to avoid reflection entirely.
  Map<dynamic, InjectionRequest> get preContained => _preContained;

  /// Determines whether to allow HTTP request method overrides.
  bool allowMethodOverrides = true;

  /// All child application mounted on this instance.
  List<Angel> get children => new List<Angel>.unmodifiable(_children);

  final Map<Pattern, Controller> _controllers = {};

  /// A set of [Controller] objects that have been loaded into the application.
  Map<Pattern, Controller> get controllers => _controllers;

  /// Indicates whether the application is running in a production environment.
  ///
  /// The criteria for this is the `ANGEL_ENV` environment variable being set to
  /// `'production'`.
  ///
  /// This value is memoized the first time you call it, so do not change environment
  /// configuration at runtime!
  bool get isProduction {
    return _isProduction ??=
        (Platform.environment['ANGEL_ENV'] == 'production');
  }

  /// The function used to bind this instance to an HTTP server.
  ServerGenerator get serverGenerator => _serverGenerator;

  /// Returns the parent instance of this application, if any.
  Angel get parent => _parent;

  /// Outputs diagnostics and debug messages.
  Logger logger;

  /// Plug-ins to be called right before server startup.
  ///
  /// If the server is never started, they will never be called.
  final List<AngelConfigurer> startupHooks = [];

  /// Plug-ins to be called right before server shutdown.
  ///
  /// If the server is never [close]d, they will never be called.
  final List<AngelConfigurer> shutdownHooks = [];

  /// Always run before responses are sent.
  ///
  /// These will only not run if a response's `willCloseItself` is set to `true`.
  final List<RequestHandler> responseFinalizers = [];

  /// Use [configuration] instead.
  @deprecated
  Map get properties {
    try {
      throw new Error();
    } catch (e, st) {
      logger?.warning(
        '`properties` is deprecated, and should not be used.',
        new UnsupportedError('`properties` is deprecated.'),
        st,
      );
    }
    return configuration;
  }

  /// The handler currently configured to run on [AngelHttpException]s.
  Function(AngelHttpException e, RequestContext req, ResponseContext res)
      errorHandler =
      (AngelHttpException e, RequestContext req, ResponseContext res) {
    if (!req.accepts('text/html', strict: true) &&
        (req.accepts('application/json') ||
            req.accepts('application/javascript'))) {
      res.json(e.toJson());
      return;
    }

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

  /// The native HttpServer running this instancce.
  HttpServer httpServer;

  /// Starts the server.
  ///
  /// Returns false on failure; otherwise, returns the HttpServer.
  Future<HttpServer> startServer([address, int port]) async {
    var host = address ?? InternetAddress.LOOPBACK_IP_V4;
    this.httpServer = await _serverGenerator(host, port ?? 0);

    for (var configurer in startupHooks) {
      await configure(configurer);
    }

    optimizeForProduction();
    _sub = httpServer.listen(handleRequest);
    return httpServer;
  }

  @override
  Route addRoute(String method, Pattern path, Object handler,
      {List middleware: const []}) {
    if (_flattened != null) {
      logger?.warning(
          'WARNING: You added a route ($method $path) to the router, after it had been optimized.');
      logger?.warning(
          'This route will be ignored, and no requests will ever reach it.');
    }

    return super.addRoute(method, path, handler, middleware: middleware ?? []);
  }

  @override
  mount(Pattern path, Router router, {bool hooked: true, String namespace}) {
    if (_flattened != null) {
      logger?.warning(
          'WARNING: You added mounted a child router ($path) on the router, after it had been optimized.');
      logger?.warning(
          'This route will be ignored, and no requests will ever reach it.');
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
  ///
  /// The server will be **COMPLETE DEFUNCT** after this operation!
  Future<HttpServer> close() async {
    HttpServer server;

    _sub?.cancel();

    if (httpServer != null) {
      server = httpServer;
      await httpServer.close(force: true);
    }

    await Future.forEach(services.values, (Service service) async {
      await service.close();
    });

    for (var plugin in shutdownHooks) await plugin(this);

    await super.close();
    _preContained.clear();
    handlerCache.clear();
    _injections.clear();
    encoders.clear();
    _serializer = god.serialize;
    _children.clear();
    _parent = null;
    logger = null;
    startupHooks.clear();
    shutdownHooks.clear();
    responseFinalizers.clear();
    _flattened = null;

    return server;
  }

  @override
  void dumpTree(
      {callback(String tree),
      String header: 'Dumping route tree:',
      String tab: '  ',
      bool showMatchers: false}) {
    if (isProduction) {
      _flattened ??= flatten(this);

      _flattened.dumpTree(
          callback: callback,
          header: header?.isNotEmpty == true
              ? header
              : (isProduction
                  ? 'Dumping flattened route tree:'
                  : 'Dumping route tree:'),
          tab: tab ?? '  ');
    } else {
      super.dumpTree(
          callback: callback,
          header: header?.isNotEmpty == true
              ? header
              : (isProduction
                  ? 'Dumping flattened route tree:'
                  : 'Dumping route tree:'),
          tab: tab ?? '  ');
    }
  }

  /// Shortcut for adding a middleware to inject a key/value pair on every request.
  void inject(key, value) {
    _injections[key] = value;
  }

  /// Shortcuts for adding converters to transform the response buffer/stream of any request.
  void injectEncoders(Map<String, Converter<List<int>, List<int>>> encoders) {
    this.encoders.addAll(encoders);
  }

  /// Shortcut for adding a middleware to inject a serialize on every request.
  void injectSerializer(ResponseSerializer serializer) {
    _serializer = serializer;
  }

  Future getHandlerResult(
      handler, RequestContext req, ResponseContext res) async {
    if (handler is RequestHandler) {
      var result = await handler(req, res);
      return await getHandlerResult(result, req, res);
    }

    if (handler is Future) {
      var result = await handler;
      return await getHandlerResult(result, req, res);
    }

    if (handler is Function) {
      var result = await runContained(handler, req, res);
      return await getHandlerResult(result, req, res);
    }

    if (handler is Stream) {
      return await getHandlerResult(await handler.toList(), req, res);
    }

    var middleware = (req.app ?? this).findMiddleware(handler);
    if (middleware != null) {
      return await getHandlerResult(middleware, req, res);
    }

    return handler;
  }

  /// Runs some [handler]. Returns `true` if request execution should continue.
  Future<bool> executeHandler(
      handler, RequestContext req, ResponseContext res) async {
    var result = await getHandlerResult(handler, req, res);

    if (result == null)
      return false;
    else if (result is bool) {
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
    var path = request.uri.path.replaceAll(_straySlashes, '');
    if (path.length == 0) path = '/';
    return RequestContext.from(request, this, path).then((req) async {
      if (_pool != null) req.inject(PoolResource, await _pool.request());
      if (_injections.isNotEmpty) _injections.forEach(req.inject);
      return req;
    });
  }

  Future<ResponseContext> createResponseContext(HttpResponse response,
          [RequestContext correspondingRequest]) =>
      new Future<ResponseContext>.value(
          new ResponseContext(response, this, correspondingRequest)
            ..serializer = (_serializer ?? god.serialize)
            ..encoders.addAll(encoders ?? {}));

  /// Attempts to find a middleware by the given name within this application.
  findMiddleware(key) {
    if (requestMiddleware.containsKey(key)) return requestMiddleware[key];
    return parent != null ? parent.findMiddleware(key) : null;
  }

  /// Attempts to find a property by the given name within this application.
  findProperty(key) {
    if (configuration.containsKey(key)) return configuration[key];
    return parent != null ? parent.findProperty(key) : null;
  }

  /// Handles an [AngelHttpException].
  Future handleAngelHttpException(AngelHttpException e, StackTrace st,
      RequestContext req, ResponseContext res, HttpRequest request,
      {bool ignoreFinalizers: false}) async {
    if (req == null || res == null) {
      try {
        logger?.severe(e, st);
        request.response
          ..statusCode = HttpStatus.INTERNAL_SERVER_ERROR
          ..write('500 Internal Server Error')
          ..close();
      } finally {
        return null;
      }
    }

    res.statusCode = e.statusCode;
    var result = await errorHandler(e, req, res);
    await executeHandler(result, req, res);
    res.end();
    return await sendResponse(request, req, res,
        ignoreFinalizers: ignoreFinalizers == true);
  }

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
      var tuple = isProduction
          ? handlerCache.putIfAbsent(cacheKey, resolveTuple)
          : resolveTuple();

      //req.inject(Zone, zone);
      //req.inject(ZoneSpecification, zoneSpec);
      req.params.addAll(tuple.item2);
      req.inject(ParseResult, tuple.item3);

      if (logger != null) req.inject(Stopwatch, new Stopwatch()..start());

      var pipeline = tuple.item1;

      for (var handler in pipeline) {
        try {
          if (handler == null || !await executeHandler(handler, req, res))
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

      if (logger != null) {
        logger.severe(e.message ?? e.toString(), error, stackTrace);
      }

      return await handleAngelHttpException(e, stackTrace, req, res, request);
    } catch (error, stackTrace) {
      var e = new AngelHttpException(error,
          stackTrace: stackTrace, message: error?.toString());

      if (logger != null) {
        logger.severe(e.message ?? e.toString(), error, stackTrace);
      }

      return await handleAngelHttpException(e, stackTrace, req, res, request);
    } finally {
      res.dispose();
    }
  }

  /// Runs several optimizations, *if* [isProduction] is `true`.
  ///
  /// * Preprocesses all dependency injection, and eliminates the burden of reflecting handlers
  /// at run-time.
  /// * [flatten]s the route tree into a linear one.
  ///
  /// You may [force] the optimization to run, if you are not running in production.
  void optimizeForProduction({bool force: false}) {
    if (isProduction == true || force == true) {
      _isProduction = true;
      _add(v) {
        if (v is Function && !_preContained.containsKey(v)) {
          _preContained[v] = preInject(v);
        }
      }

      void _walk(Router router) {
        router.requestMiddleware.forEach((k, v) => _add(v));
        router.middleware.forEach(_add);
        router.routes.forEach((r) {
          r.handlers.forEach(_add);
          if (r is SymlinkRoute) _walk(r.router);
        });
      }

      _flattened ??= flatten(this);

      _walk(_flattened);

      logger?.config('Angel is running in production mode.');
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

  /// Sends a response.
  Future sendResponse(
      HttpRequest request, RequestContext req, ResponseContext res,
      {bool ignoreFinalizers: false}) {
    if (res.willCloseItself) return new Future.value();

    Future finalizers = ignoreFinalizers == true
        ? new Future.value()
        : responseFinalizers.fold<Future>(
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

      if (logger != null) {
        var sw = req.grab<Stopwatch>(Stopwatch);

        if (sw.isRunning) {
          sw?.stop();
          logger.info("${res.statusCode} ${req.method} ${req.uri} (${sw
              ?.elapsedMilliseconds ?? 'unknown'} ms)");
        }
      }
    });
  }

  /// Limits the maximum number of requests to be handled concurrently by this instance.
  ///
  /// You can optionally provide a [timeout] to limit the amount of time a request can be
  /// handled before.
  void throttle(int maxConcurrentRequests, {Duration timeout}) {
    _pool = new Pool(maxConcurrentRequests, timeout: timeout);
  }

  /// Applies an [AngelConfigurer] to this instance.
  Future configure(AngelConfigurer configurer) async {
    await configurer(this);
  }

  /// Mounts the child on this router. If [routable] is `null`,
  /// then this method will add a handler as a global middleware instead.
  ///
  /// If the router is an [Angel] instance, all controllers
  /// will be copied, as well as services and response finalizers.
  ///
  /// [before] and [after] will be preserved.
  ///
  /// NOTE: The above will not be properly copied if [path] is
  /// a [RegExp].
  @override
  use(path, [@checked Routable routable, String namespace = null]) {
    if (routable == null) return all('*', path);

    var head = path.toString().replaceAll(_straySlashes, '');

    if (routable is Angel) {
      _children.add(routable.._parent = this);
      _preContained.addAll(routable._preContained);

      if (routable.responseFinalizers.isNotEmpty) {
        responseFinalizers.add((req, res) async {
          if (req.path.replaceAll(_straySlashes, '').startsWith(head)) {
            for (var finalizer in routable.responseFinalizers)
              await finalizer(req, res);
          }

          return true;
        });
      }

      routable._controllers.forEach((k, v) {
        var tail = k.toString().replaceAll(_straySlashes, '');
        _controllers['$head/$tail'.replaceAll(_straySlashes, '')] = v;
      });

      routable.services.forEach((k, v) {
        var tail = k.toString().replaceAll(_straySlashes, '');
        services['$head/$tail'.replaceAll(_straySlashes, '')] = v;
      });
    }

    if (routable is Service) {
      routable.app = this;
    }

    return super.use(path, routable, namespace);
  }

  /// Default constructor. ;)
  Angel() : super() {
    bootstrapContainer();
    createZoneForRequest = defaultZoneCreator;
  }

  Future<ZoneSpecification> defaultZoneCreator(request, req, res) async {
    return new ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        if (logger != null) {
          logger.info(line);
        } else {
          return parent.print(zone, line);
        }
      },
    );
  }

  /// An instance mounted on a server started by the [serverGenerator].
  factory Angel.custom(ServerGenerator serverGenerator) {
    return new Angel().._serverGenerator = serverGenerator;
  }

  factory Angel.fromSecurityContext(SecurityContext context) {
    var app = new Angel();

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
