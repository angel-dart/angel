library angel_framework.http.controller;

import 'dart:async';
import 'package:angel_container/angel_container.dart';
import 'package:angel_route/angel_route.dart';
import 'package:meta/meta.dart';
import 'package:recase/recase.dart';
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

  SymlinkRoute<RequestHandler> _mountPoint;

  /// The route at which this controller is mounted on the server.
  SymlinkRoute<RequestHandler> get mountPoint => _mountPoint;

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
  Future<String> applyRoutes(
      Router<RequestHandler> router, Reflector reflector) async {
    // Load global expose decl
    var classMirror = reflector.reflectClass(this.runtimeType);
    Expose exposeDecl = findExpose(reflector);

    if (exposeDecl == null) {
      throw Exception("All controllers must carry an @Expose() declaration.");
    }

    var routable = Routable();
    _mountPoint = router.mount(exposeDecl.path, routable);
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

      // Ignore built-in methods.
      if (methodName != 'toString' &&
          methodName != 'noSuchMethod' &&
          methodName != 'call' &&
          methodName != 'equals' &&
          methodName != '==') {
        var exposeDecl = decl.function.annotations
            .map((m) => m.reflectee)
            .firstWhere((r) => r is Expose, orElse: () => null) as Expose;

        if (exposeDecl == null) {
          // If this has a @noExpose, return null.
          if (decl.function.annotations.any((m) => m.reflectee is NoExpose)) {
            return;
          } else {
            // Otherwise, create an @Expose.
            exposeDecl = Expose(null);
          }
        }

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

        // If there is no path, reverse-engineer one.
        var path = exposeDecl.path;
        var httpMethod = exposeDecl.method ?? 'GET';
        if (path == null) {
          // Try to build a route path by finding all potential
          // path segments, and then joining them.
          var parts = <String>[];

          // If the name starts with get/post/patch, etc., then that
          // should be the path.
          var methodMatch = _methods.firstMatch(method.name);
          if (methodMatch != null) {
            var rest = method.name.replaceAll(_methods, '');
            var restPath = ReCase(rest.isEmpty ? 'index' : rest)
                .snakeCase
                .replaceAll(_rgxMultipleUnderscores, '_');
            httpMethod = methodMatch[1].toUpperCase();

            if (['index', 'by_id'].contains(restPath)) {
              parts.add('/');
            } else {
              parts.add(restPath);
            }
          }
          // If the name does NOT start with get/post/patch, etc. then
          // snake_case-ify the name, and add it to the list of segments.
          // If the name is index, though, add "/".
          else {
            if (method.name == 'index') {
              parts.add('/');
            } else {
              parts.add(ReCase(method.name)
                  .snakeCase
                  .replaceAll(_rgxMultipleUnderscores, '_'));
            }
          }

          // Try to infer String, int, or double. We called
          // preInject() earlier, so we can figure out the types
          // of required parameters, and add those to the path.
          for (var p in injection.required) {
            if (p is List && p.length == 2 && p[0] is String && p[1] is Type) {
              var name = p[0] as String;
              var type = p[1] as Type;
              if (type == String) {
                parts.add(':$name');
              } else if (type == int) {
                parts.add('int:$name');
              } else if (type == double) {
                parts.add('double:$name');
              }
            }
          }

          path = parts.join('/');
          if (!path.startsWith('/')) path = '/$path';
        }

        routeMappings[name] = routable.addRoute(
            httpMethod, path, handleContained(reflectedMethod, injection),
            middleware: middleware);
      }
    };
  }

  /// Used to add additional routes or middlewares to the router from within
  /// a [Controller].
  ///
  /// ```dart
  /// @override
  /// FutureOr<void> configureRoutes(Routable routable) {
  ///   routable.all('*', myMiddleware);
  /// }
  /// ```
  FutureOr<void> configureRoutes(Routable routable) {}

  static final RegExp _methods = RegExp(r'^(get|post|patch|delete)');
  static final RegExp _rgxMultipleUnderscores = RegExp(r'__+');

  /// Finds the [Expose] declaration for this class.
  ///
  /// If [concreteOnly] is `false`, then if there is no actual
  /// [Expose], one will be automatically created.
  Expose findExpose(Reflector reflector, {bool concreteOnly = false}) {
    var existing = reflector
        .reflectClass(runtimeType)
        .annotations
        .map((m) => m.reflectee)
        .firstWhere((r) => r is Expose, orElse: () => null) as Expose;
    return existing ??
        (concreteOnly
            ? null
            : Expose(ReCase(runtimeType.toString())
                .snakeCase
                .replaceAll('_controller', '')
                .replaceAll('_ctrl', '')
                .replaceAll(_rgxMultipleUnderscores, '_')));
  }
}
