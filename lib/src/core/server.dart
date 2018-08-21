library angel_framework.http.server;

import 'dart:async';
import 'dart:collection' show HashMap;
import 'dart:convert';
import 'dart:io';

import 'package:angel_container/angel_container.dart';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:angel_route/angel_route.dart';
import 'package:combinator/combinator.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';
import 'package:tuple/tuple.dart';

import '../http/http.dart';
import 'hooked_service.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'routable.dart';
import 'service.dart';

//final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// A function that configures an [Angel] server in some way.
typedef FutureOr AngelConfigurer(Angel app);

/// A function that asynchronously generates a view from the given path and data.
typedef FutureOr<String> ViewGenerator(String path,
    [Map<String, dynamic> data]);

/// A powerful real-time/REST/MVC server class.
class Angel extends Routable {
  static ViewGenerator noViewEngineConfigured =
      (String view, [Map data]) => 'No view engine has been configured yet.';

  final List<Angel> _children = [];
  final Map<String,
          Tuple3<List, Map<String, dynamic>, ParseResult<Map<String, dynamic>>>>
      handlerCache = new HashMap();

  Router _flattened;
  AngelHttp _http;
  bool _isProduction;
  Angel _parent;

  /// A global Map of converters that can transform responses bodies.
  final Map<String, Converter<List<int>, List<int>>> encoders = {};

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

  /// A [Map] of application-specific data that can be accessed by any
  /// piece of code that can see this [Angel] instance.
  ///
  /// Packages like `package:angel_configuration` populate this map
  /// for you.
  final Map configuration = {};

  /// When set to `true` (default: `false`), the request body will be parsed
  /// automatically; otherwise, you must call [RequestContext].parseBody() manually,
  /// or use `lazyBody()`.
  bool eagerParseRequestBodies = false;

  /// When set to `true`, the original body bytes will be stored
  /// on requests. `false` by default.
  bool keepRawRequestBuffers = false;

  /// A function that renders views.
  ///
  /// Called by [ResponseContext]@`render`.
  ViewGenerator viewGenerator = noViewEngineConfigured;

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

    res.contentType = new MediaType('text', 'html', {'charset': 'utf8'});
    res.statusCode = e.statusCode;
    res.write("<!DOCTYPE html><html><head><title>${e.message}</title>");
    res.write("</head><body><h1>${e.message}</h1><ul>");

    for (String error in e.errors) {
      res.write("<li>$error</li>");
    }

    res.write("</ul></body></html>");
    res.close();
  };

  @override
  Route<RequestHandler> addRoute(
      String method, String path, RequestHandler handler,
      {Iterable<RequestHandler> middleware: const <RequestHandler>[]}) {
    if (_flattened != null) {
      logger?.warning(
          'WARNING: You added a route ($method $path) to the router, after it had been optimized.');
      logger?.warning(
          'This route will be ignored, and no requests will ever reach it.');
    }

    return super.addRoute(method, path, handler, middleware: middleware ?? []);
  }

  @override
  mount(String path, Router<RequestHandler> router) {
    if (_flattened != null) {
      logger?.warning(
          'WARNING: You added mounted a child router ($path) on the router, after it had been optimized.');
      logger?.warning(
          'This route will be ignored, and no requests will ever reach it.');
    }

    if (router is Angel) {
      router._parent = this;
      _children.add(router);
    }

    return super.mount(path.toString(), router);
  }

  /// Loads some base dependencies into the service container.
  void bootstrapContainer() {
    if (runtimeType != Angel) {
      container.registerSingleton(this);
    }

    container.registerSingleton<Angel>(this);
    container.registerSingleton<Routable>(this);
    container.registerSingleton<Router>(this);
  }

  /// Shuts down the server, and closes any open [StreamController]s.
  ///
  /// The server will be **COMPLETELY DEFUNCT** after this operation!
  Future close() {
    Future.forEach(services.values, (Service service) {
      service.close();
    });

    super.close();
    viewGenerator = noViewEngineConfigured;
    _preContained.clear();
    handlerCache.clear();
    encoders.clear();
    //_serializer = json.encode;
    _children.clear();
    _parent = null;
    logger = null;
    startupHooks.clear();
    shutdownHooks.clear();
    responseFinalizers.clear();
    _flattened = null;
    _http?.close();
    return new Future.value(_http?.httpServer);
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

  Future getHandlerResult(handler, RequestContext req, ResponseContext res) {
    if (handler is RequestHandler) {
      var result = handler(req, res);
      return getHandlerResult(result, req, res);
    }

    if (handler is Future) {
      return handler.then((result) => getHandlerResult(result, req, res));
    }

    if (handler is Function) {
      var result = runContained(handler, req, res);
      return getHandlerResult(result, req, res);
    }

    if (handler is Stream) {
      return getHandlerResult(handler.toList(), req, res);
    }

    return new Future.value(handler);
  }

  /// Runs some [handler]. Returns `true` if request execution should continue.
  Future<bool> executeHandler(
      handler, RequestContext req, ResponseContext res) {
    return getHandlerResult(handler, req, res).then((result) {
      if (result == null)
        return false;
      else if (result is bool) {
        return result;
      } else if (result != null) {
        return res.serialize(result);
      } else
        return res.isOpen;
    });
  }

  /// Attempts to find a property by the given name within this application.
  findProperty(key) {
    if (configuration.containsKey(key)) return configuration[key];
    return parent != null ? parent.findProperty(key) : null;
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
      _flattened ??= flatten(this);
      logger?.config('Angel is running in production mode.');
    }
  }

  /// Run a function after injecting from service container.
  /// If this function has been reflected before, then
  /// the execution will be faster, as the injection requirements were stored beforehand.
  Future runContained(
      Function handler, RequestContext req, ResponseContext res) {
    return new Future.sync(() {
      if (_preContained.containsKey(handler)) {
        return handleContained(handler, _preContained[handler])(req, res);
      }

      return runReflected(handler, req, res);
    });
  }

  /// Runs with DI, and *always* reflects. Prefer [runContained].
  Future runReflected(
      Function handler, RequestContext req, ResponseContext res) {
    var h = handleContained(
        handler,
        _preContained[handler] =
            preInject(handler, req.app.container.reflector));
    return new Future.sync(() => h(req, res));
    // return   closureMirror.apply(args).reflectee;
  }

  /// Applies an [AngelConfigurer] to this instance.
  Future configure(AngelConfigurer configurer) {
    return new Future.sync(() => configurer(this));
  }

  /// Shorthand for calling `all('*', handler)`.
  Route<RequestHandler> fallback(RequestHandler handler) {
    return all('*', handler);
  }

  @override
  HookedService use(String path, Service service) {
    service.app = this;
    return super.use(path, service)..app = this;
  }

  Angel(
      {Reflector reflector: const EmptyReflector(),
      this.logger,
      this.eagerParseRequestBodies: false,
      this.allowMethodOverrides: true,
      this.keepRawRequestBuffers: false,
      this.serializer,
      this.viewGenerator})
      : super(reflector) {
    bootstrapContainer();
    viewGenerator ??= noViewEngineConfigured;
    serializer ??= json.encode;
  }
}
