library angel_framework.http.controller;

import 'dart:async';
import 'dart:mirrors';
import 'package:angel_route/angel_route.dart';
import 'package:meta/meta.dart';
import '../core/core.dart';

/// Supports grouping routes with shared functionality.
class Controller {
  Angel _app;

  /// The [Angel] application powering this controller.
  Angel get app => _app;

  final bool debug;

  /// If `true` (default), this class will inject itself as a singleton into the [app]'s container when bootstrapped.
  final bool injectSingleton;

  /// Middleware to run before all handlers in this class.
  List middleware = [];

  /// A mapping of route paths to routes, produced from the [Expose] annotations on this class.
  Map<String, Route> routeMappings = {};

  Controller({this.debug: false, this.injectSingleton: true});

  @mustCallSuper
  Future configureServer(Angel app)  {
    _app = app;

    if (injectSingleton != false) _app.container.singleton(this);

    // Load global expose decl
    ClassMirror classMirror = reflectClass(this.runtimeType);
    Expose exposeDecl = findExpose();

    if (exposeDecl == null) {
      throw new Exception(
          "All controllers must carry an @Expose() declaration.");
    }

    var routable = new Routable();
    app.use(exposeDecl.path, routable);
    TypeMirror typeMirror = reflectType(this.runtimeType);
    String name = exposeDecl.as?.isNotEmpty == true
        ? exposeDecl.as
        : MirrorSystem.getName(typeMirror.simpleName);

    app.controllers[name] = this;

    // Pre-reflect methods
    InstanceMirror instanceMirror = reflect(this);
    final handlers = []..addAll(exposeDecl.middleware)..addAll(middleware);
    final routeBuilder = _routeBuilder(instanceMirror, routable, handlers);
    classMirror.instanceMembers.forEach(routeBuilder);
    configureRoutes(routable);
    return new Future.value();
  }

  Function _routeBuilder(
      InstanceMirror instanceMirror, Routable routable, List handlers) {
    return (Symbol methodName, MethodMirror method) {
      if (method.isRegularMethod &&
          methodName != #toString &&
          methodName != #noSuchMethod &&
          methodName != #call &&
          methodName != #equals &&
          methodName != #==) {
        Expose exposeDecl = method.metadata
            .map((m) => m.reflectee)
            .firstWhere((r) => r is Expose, orElse: () => null);

        if (exposeDecl == null) return;

        var reflectedMethod = instanceMirror.getField(methodName).reflectee;
        var middleware = []..addAll(handlers)..addAll(exposeDecl.middleware);
        String name = exposeDecl.as?.isNotEmpty == true
            ? exposeDecl.as
            : MirrorSystem.getName(methodName);

        // Check if normal
        if (method.parameters.length == 2 &&
            method.parameters[0].type.reflectedType == RequestContext &&
            method.parameters[1].type.reflectedType == ResponseContext) {
          // Create a regular route
          routeMappings[name] = routable
              .addRoute(exposeDecl.method, exposeDecl.path, (req, res)  {
            var result =   reflectedMethod(req, res);
            return result is RequestHandler ?   result(req, res) : result;
          }, middleware: middleware);
          return;
        }

        var injection = preInject(reflectedMethod);

        if (exposeDecl?.allowNull?.isNotEmpty == true)
          injection.optional?.addAll(exposeDecl.allowNull);

        routeMappings[name] = routable.addRoute(exposeDecl.method,
            exposeDecl.path, handleContained(reflectedMethod, injection),
            middleware: middleware);
      }
    };
  }

  /// Used to add additional routes to the router from within a [Controller].
  void configureRoutes(Routable routable) {}

  /// Finds the [Expose] declaration for this class.
  Expose findExpose() => reflectClass(runtimeType)
      .metadata
      .map((m) => m.reflectee)
      .firstWhere((r) => r is Expose, orElse: () => null);
}
