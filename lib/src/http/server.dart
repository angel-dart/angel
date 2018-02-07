library angel_framework.http.server;

import 'dart:async';
import 'dart:collection' show HashMap;
import 'dart:convert';
import 'dart:io';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:angel_route/angel_route.dart';
import 'package:combinator/combinator.dart';
export 'package:container/container.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';
import 'angel_base.dart';
import 'angel_http.dart';
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
  AngelHttp _http;
  bool _isProduction;
  Angel _parent;
  ServerGenerator _serverGenerator = HttpServer.bind;

  /// A global Map of converters that can transform responses bodies.
  final Map<String, Converter<List<int>, List<int>>> encoders = {};

  final Map _injections = {};

  /// Creates a safe zone within which a request can be handled, without crashing the application.
  Future<ZoneSpecification> Function(
          HttpRequest request, RequestContext req, ResponseContext res)
      createZoneForRequest;

  final Map<dynamic, InjectionRequest> _preContained = {};

  /// A middleware to inject a serialize on every request.
  String Function(dynamic) serializer;

  /// A [Map] of dependency data obtained via reflection.
  ///
  /// You may modify this [Map] yourself if you intend to avoid reflection entirely.
  Map<dynamic, InjectionRequest> get preContained => _preContained;

  /// Returns the [flatten]ed version of this router in production.
  Router get optimizedRouter => _flattened ?? this;

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

  /// All global dependencies injected into the application.
  Map get injections => _injections;

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

    res.headers['content-type'] = 'text/html';
    res.statusCode = e.statusCode;
    res.write("<!DOCTYPE html><html><head><title>${e.message}</title>");
    res.write("</head><body><h1>${e.message}</h1><ul>");

    for (String error in e.errors) {
      res.write("<li>$error</li>");
    }

    res.write("</ul></body></html>");
    res.end();
  };

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  HttpServer httpServer;

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  Future<HttpServer> startServer([address, int port]) {
    _http ??= new AngelHttp(this);
    return _http.startServer(address, port);
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
  Future close() async {
    await Future.forEach(services.values, (Service service) async {
      await service.close();
    });

    await super.close();
    _preContained.clear();
    handlerCache.clear();
    _injections.clear();
    encoders.clear();
    //_serializer = god.serialize;
    _children.clear();
    _parent = null;
    logger = null;
    startupHooks.clear();
    shutdownHooks.clear();
    responseFinalizers.clear();
    _flattened = null;
    await _http.close();
    return _http.httpServer;
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

  /// Prefer directly setting [serializer].
  @deprecated
  void injectSerializer(String serializer(x)) {
    this.serializer = serializer;
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
      // TODO: Make `serialize` return a bool, return this as the value.
      // Do this wherever applicable
      res.serialize(result,
          contentType: res.headers['content-type'] ?? 'application/json');
      return false;
    } else
      return res.isOpen;
  }

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  Future<RequestContext> createRequestContext(HttpRequest request) {
    return _http.createRequestContext(request);
  }

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  Future<ResponseContext> createResponseContext(HttpResponse response,
          [RequestContext correspondingRequest]) =>
      _http.createResponseContext(response, correspondingRequest);

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

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  Future handleAngelHttpException(AngelHttpException e, StackTrace st,
      RequestContext req, ResponseContext res, HttpRequest request,
      {bool ignoreFinalizers: false}) {
    return _http.handleAngelHttpException(e, st, req, res, request,
        ignoreFinalizers: ignoreFinalizers == true);
  }

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  Future handleRequest(HttpRequest request) {
    return _http.handleRequest(request);
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

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  Future sendResponse(
      HttpRequest request, RequestContext req, ResponseContext res,
      {bool ignoreFinalizers: false}) {
    return _http.sendResponse(request, req, res);
  }

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  void throttle(int maxConcurrentRequests, {Duration timeout}) {
    _http?.throttle(maxConcurrentRequests, timeout: timeout);
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

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  factory Angel.custom(ServerGenerator serverGenerator) {
    var app = new Angel();
    return app.._http = new AngelHttp.custom(app, serverGenerator);
  }

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  factory Angel.fromSecurityContext(SecurityContext context) {
    var app = new Angel();

    app._http =
        new AngelHttp.custom(app, (InternetAddress address, int port) async {
      return await HttpServer.bindSecure(address, port, context);
    });

    return app;
  }

  /// Use the serving methods in [AngelHttp] instead.
  @deprecated
  factory Angel.secure(String certificateChainPath, String serverKeyPath,
      {String password}) {
    var app = new Angel();
    return app
      .._http = new AngelHttp.secure(app, certificateChainPath, serverKeyPath,
          password: password);
  }
}
