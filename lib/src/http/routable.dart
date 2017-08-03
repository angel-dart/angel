library angel_framework.http.routable;

import 'dart:async';
import 'package:angel_route/angel_route.dart';
import 'package:meta/meta.dart';
import '../util.dart';
import 'angel_base.dart';
import 'controller.dart';
import 'hooked_service.dart';
import 'metadata.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'service.dart';

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// A function that intercepts a request and determines whether handling of it should continue.
typedef Future<bool> RequestMiddleware(RequestContext req, ResponseContext res);

/// A function that receives an incoming [RequestContext] and responds to it.
typedef Future RequestHandler(RequestContext req, ResponseContext res);

/// Sequentially runs a list of [handlers] of middleware, and returns early if any does not
/// return `true`. Works well with [Router].chain.
RequestMiddleware waterfall(List handlers) {
  return (RequestContext req, res) async {
    for (var handler in handlers) {
      var result = await req.app.executeHandler(handler, req, res);
      if (result != true) return result;
    }

    return true;
  };
}

/// A routable server that can handle dynamic requests.
class Routable extends Router {
  final Map<Pattern, Controller> _controllers = {};
  final Map<Pattern, Service> _services = {};
  final Map properties = {};

  Routable({bool debug: false}) : super(debug: debug);

  /// Additional filters to be run on designated requests.
  @override
  final Map<String, RequestMiddleware> requestMiddleware = {};

  /// A set of [Service] objects that have been mapped into routes.
  Map<Pattern, Service> get services => _services;

  /// A set of [Controller] objects that have been loaded into the application.
  Map<Pattern, Controller> get controllers => _controllers;

  StreamController<Service> _onService =
      new StreamController<Service>.broadcast();

  /// Fired whenever a service is added to this instance.
  ///
  /// **NOTE**: This is a broadcast stream.
  Stream<Service> get onService => _onService.stream;

  /// Assigns a middleware to a name for convenience.
  @override
  registerMiddleware(String name, @checked RequestHandler middleware) =>
      super.registerMiddleware(name, middleware);

  /// Retrieves the service assigned to the given path.
  Service service(Pattern path) =>
      _services[path] ??
      _services[path.toString().replaceAll(_straySlashes, '')];

  /// Retrieves the controller with the given name.
  Controller controller(String name) => controllers[name];

  @override
  Route addRoute(String method, Pattern path, Object handler,
      {List middleware: const []}) {
    final List handlers = [];
    // Merge @Middleware declaration, if any
    Middleware middlewareDeclaration = getAnnotation(handler, Middleware);
    if (middlewareDeclaration != null) {
      handlers.addAll(middlewareDeclaration.handlers);
    }

    final List handlerSequence = [];
    handlerSequence.addAll(middleware ?? []);
    handlerSequence.addAll(handlers);

    return super.addRoute(method, path, handler, middleware: handlerSequence);
  }

  void use(Pattern path, Router router,
      {bool hooked: true, String namespace: null}) {
    Router _router = router;
    Service service;

    // If we need to hook this service, do it here. It has to be first, or
    // else all routes will point to the old service.
    if (router is Service) {
      Hooked hookedDeclaration = getAnnotation(router, Hooked);
      _router = service = (hookedDeclaration != null || hooked)
          ? new HookedService(router)
          : router;
      _services[path
          .toString()
          .trim()
          .replaceAll(new RegExp(r'(^/+)|(/+$)'), '')] = service;
      service.addRoutes();

      if (_router is HookedService && _router != router)
        router.onHooked(_router);
    }

    final handlers = [];

    if (_router is AngelBase) {
      handlers.add((RequestContext req, ResponseContext res) async {
        req.app = _router;
        res.app = _router;
        return true;
      });
    }

    // Let's copy middleware, heeding the optional middleware namespace.
    String middlewarePrefix = namespace != null ? "$namespace." : "";

    Map copiedMiddleware = new Map.from(router.requestMiddleware);
    for (String middlewareName in copiedMiddleware.keys) {
      requestMiddleware.putIfAbsent("$middlewarePrefix$middlewareName",
          () => copiedMiddleware[middlewareName]);
    }

    // Also copy properties...
    if (router is Routable) {
      Map copiedProperties = new Map.from(router.properties);
      for (String propertyName in copiedProperties.keys) {
        properties.putIfAbsent("$middlewarePrefix$propertyName",
                () => copiedMiddleware[propertyName]);
      }
    }

    // _router.dumpTree(header: 'Mounting on "$path":');
    // root.child(path, debug: debug, handlers: handlers).addChild(router.root);
    mount(path, _router);

    if (_router is Routable) {
      // Copy services, too. :)
      for (Pattern servicePath in _router._services.keys) {
        String newServicePath =
            path.toString().trim().replaceAll(new RegExp(r'(^/+)|(/+$)'), '') +
                '/$servicePath';
        _services[newServicePath] = _router._services[servicePath];
      }
    }

    if (service != null) {
      if (_onService.hasListener) _onService.add(service);
    }
  }
}
