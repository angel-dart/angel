library angel_framework.http.controller;

import 'dart:async';
import 'package:angel_container/angel_container.dart';
import 'package:angel_route/angel_route.dart';
import 'package:meta/meta.dart';

import '../core/core.dart';

/// Supports grouping routes with shared functionality.
class Controller {
  Angel _app;

  /// The [Angel] application powering this controller.
  Angel get app => _app;

  /// If `true` (default), this class will inject itself as a singleton into the [app]'s container when bootstrapped.
  final bool injectSingleton;

  /// Middleware to run before all handlers in this class.
  List<RequestHandler> middleware = [];

  /// A mapping of route paths to routes, produced from the [Expose] annotations on this class.
  Map<String, Route> routeMappings = {};

  Controller({this.injectSingleton = true});

  /// Applies routes, DI, and other configuration to an [app].
  @mustCallSuper
  Future<void> configureServer(Angel app) async {
    _app = app;

    if (injectSingleton != false) {
      if (!app.container.has(runtimeType)) {
        _app.container.registerSingleton(this, as: runtimeType);
      }
    }

    var name = await applyRoutes(app, app.container.reflector);
    app.controllers[name] = this;
    return null;
  }

  /// Applies the routes from this [Controller] to some [router].
  Future<String> applyRoutes(Router router, Reflector reflector) async {
    // Load global expose decl
    var classMirror = reflector.reflectClass(this.runtimeType);
    Expose exposeDecl = findExpose(reflector);

    if (exposeDecl == null) {
      throw Exception("All controllers must carry an @Expose() declaration.");
    }

    var routable = Routable();
    router.mount(exposeDecl.path, routable);
    var typeMirror = reflector.reflectType(this.runtimeType);

    // Pre-reflect methods
    var instanceMirror = reflector.reflectInstance(this);
    final handlers = <RequestHandler>[]
      ..addAll(exposeDecl.middleware)
      ..addAll(middleware);
    final routeBuilder =
        _routeBuilder(reflector, instanceMirror, routable, handlers);
    await configureRoutes(routable);
    classMirror.declarations.forEach(routeBuilder);

    // Return the name.
    return exposeDecl.as?.isNotEmpty == true ? exposeDecl.as : typeMirror.name;
  }

  void Function(ReflectedDeclaration) _routeBuilder(
      Reflector reflector,
      ReflectedInstance instanceMirror,
      Routable routable,
      Iterable<RequestHandler> handlers) {
    return (ReflectedDeclaration decl) {
      var methodName = decl.name;

      if (methodName != 'toString' &&
          methodName != 'noSuchMethod' &&
          methodName != 'call' &&
          methodName != 'equals' &&
          methodName != '==') {
        var exposeDecl = decl.function.annotations
            .map((m) => m.reflectee)
            .firstWhere((r) => r is Expose, orElse: () => null) as Expose;

        if (exposeDecl == null) return;

        var reflectedMethod =
            instanceMirror.getField(methodName).reflectee as Function;
        var middleware = <RequestHandler>[]
          ..addAll(handlers)
          ..addAll(exposeDecl.middleware);
        String name =
            exposeDecl.as?.isNotEmpty == true ? exposeDecl.as : methodName;

        // Check if normal
        var method = decl.function;
        if (method.parameters.length == 2 &&
            method.parameters[0].type.reflectedType == RequestContext &&
            method.parameters[1].type.reflectedType == ResponseContext) {
          // Create a regular route
          routeMappings[name] = routable
              .addRoute(exposeDecl.method, exposeDecl.path,
                  (RequestContext req, ResponseContext res) {
            var result = reflectedMethod(req, res);
            return result is RequestHandler ? result(req, res) : result;
          }, middleware: middleware);
          return;
        }

        var injection = preInject(reflectedMethod, reflector);

        if (exposeDecl?.allowNull?.isNotEmpty == true) {
          injection.optional?.addAll(exposeDecl.allowNull);
        }

        routeMappings[name] = routable.addRoute(exposeDecl.method,
            exposeDecl.path, handleContained(reflectedMethod, injection),
            middleware: middleware);
      }
    };
  }

  /// Used to add additional routes to the router from within a [Controller].
  FutureOr<void> configureRoutes(Routable routable) {}

  /// Finds the [Expose] declaration for this class.
  Expose findExpose(Reflector reflector) => reflector
      .reflectClass(runtimeType)
      .annotations
      .map((m) => m.reflectee)
      .firstWhere((r) => r is Expose, orElse: () => null) as Expose;
}
