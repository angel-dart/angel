library angel_framework.http.routable;

import 'dart:async';

import 'package:angel_container/angel_container.dart';
import 'package:angel_route/angel_route.dart';

import '../util.dart';
import 'hooked_service.dart';
import 'metadata.dart';
import 'request_context.dart';
import 'response_context.dart';
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
class Routable extends Router<RequestHandler> {
  final Map<Pattern, Service> _services = {};
  final Map configuration = {};

  final Container _container;

  Routable([Reflector reflector])
      : _container = reflector == null ? null : new Container(reflector),
        super();

  /// A [Container] used to inject dependencies.
  Container get container => _container;

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
  Route<RequestHandler> addRoute(
      String method, String path, RequestHandler handler,
      {Iterable<RequestHandler> middleware: const <RequestHandler>[]}) {
    final handlers = <RequestHandler>[];
    // Merge @Middleware declaration, if any
    Middleware middlewareDeclaration =
        getAnnotation(handler, Middleware, _container?.reflector);
    if (middlewareDeclaration != null) {
      handlers.addAll(middlewareDeclaration.handlers);
    }

    final handlerSequence = <RequestHandler>[];
    handlerSequence.addAll(middleware ?? []);
    handlerSequence.addAll(handlers);

    return super.addRoute(method, path.toString(), handler,
        middleware: handlerSequence);
  }

  /// Mounts a [service] at the given [path].
  ///
  /// Returns a [HookedService] that can be used to hook into
  /// events dispatched by this service.
  HookedService<Id, Data, T> use<Id, Data, T extends Service<Id, Data>>(
      String path, T service) {
    var hooked = new HookedService<Id, Data, T>(service);
    _services[path
        .toString()
        .trim()
        .replaceAll(new RegExp(r'(^/+)|(/+$)'), '')] = hooked;
    hooked.addRoutes();
    mount(path.toString(), hooked);
    service.onHooked(hooked);
    _onService.add(hooked);
    return hooked;
  }
}
