library angel_framework.http.routable;

import 'dart:async';

import 'package:angel_route/angel_route.dart';

import '../util.dart';
import 'hooked_service.dart';
import 'metadata.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'server.dart';
import 'service.dart';

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// A function that receives an incoming [RequestContext] and responds to it.
typedef FutureOr RequestHandler(RequestContext req, ResponseContext res);

/// Sequentially runs a list of [handlers] of middleware, and returns early if any does not
/// return `true`. Works well with [Router].chain.
RequestHandler waterfall(Iterable<RequestHandler> handlers) {
  return (req, res) {
    Future Function() runPipeline;

    for (var handler in handlers) {
      if (handler == null) break;

      if (runPipeline == null)
        runPipeline = () => Future.sync(() => handler(req, res));
      else {
        var current = runPipeline;
        runPipeline = () => current().then((result) => !res.isOpen
            ? new Future.value(result)
            : req.app.executeHandler(handler, req, res));
      }
    }

    runPipeline ??= () => new Future.value();
    return runPipeline();
  };
}

/// A routable server that can handle dynamic requests.
class Routable extends Router {
  final Map<Pattern, Service> _services = {};
  final Map configuration = {};

  Routable() : super();

  void close() {
    _services.clear();
    configuration.clear();
    _onService.close();
  }

  /// A set of [Service] objects that have been mapped into routes.
  Map<Pattern, Service> get services => _services;

  StreamController<Service> _onService =
      new StreamController<Service>.broadcast();

  /// Fired whenever a service is added to this instance.
  ///
  /// **NOTE**: This is a broadcast stream.
  Stream<Service> get onService => _onService.stream;

  /// Retrieves the service assigned to the given path.
  Service service(Pattern path) =>
      _services[path] ??
      _services[path.toString().replaceAll(_straySlashes, '')];

  @override
  Route addRoute(String method, String path, Object handler,
      {Iterable middleware: const []}) {
    final List handlers = [];
    // Merge @Middleware declaration, if any
    Middleware middlewareDeclaration = getAnnotation(handler, Middleware);
    if (middlewareDeclaration != null) {
      handlers.addAll(middlewareDeclaration.handlers);
    }

    final List handlerSequence = [];
    handlerSequence.addAll(middleware ?? []);
    handlerSequence.addAll(handlers);

    return super.addRoute(method, path.toString(), handler,
        middleware: handlerSequence);
  }

  /// Mounts the given [router] on this instance.
  ///
  /// The [router] may only omitted when called via
  /// an [Angel] instance.
  ///
  /// Returns either a [Route] or a [Service] (if one was mounted).
  use(path, [Router router, String namespace = null]) {
    Router _router = router;
    Service service;

    // If we need to hook this service, do it here. It has to be first, or
    // else all routes will point to the old service.
    if (router is Service) {
      _router = service = new HookedService(router);
      _services[path
          .toString()
          .trim()
          .replaceAll(new RegExp(r'(^/+)|(/+$)'), '')] = service;
      service.addRoutes();

      if (_router is HookedService && _router != router)
        router.onHooked(_router);
    }

    final handlers = [];

    if (_router is Angel) {
      handlers.add((RequestContext req, ResponseContext res) {
        req.app = _router as Angel;
        res.app = _router as Angel;
        return true;
      });
    }

    // Let's copy middleware, heeding the optional middleware namespace.
    String middlewarePrefix = namespace != null ? "$namespace." : "";

    // Also copy properties...
    if (router is Routable) {
      Map copiedProperties = new Map.from(router.configuration);
      for (String propertyName in copiedProperties.keys) {
        configuration.putIfAbsent("$middlewarePrefix$propertyName",
            () => copiedProperties[propertyName]);
      }
    }

    // _router.dumpTree(header: 'Mounting on "$path":');
    // root.child(path, debug: debug, handlers: handlers).addChild(router.root);
    var mounted = mount(path.toString(), _router);

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

    return service ?? mounted;
  }
}
