library angel_framework.http.controller;

import 'dart:async';
import 'dart:mirrors';
import 'package:angel_route/angel_route.dart';
import 'angel_base.dart';
import 'angel_http_exception.dart';
import 'metadata.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'routable.dart';

class Controller {
  AngelBase app;
  List middleware = [];
  Map<String, Route> routeMappings = {};
  Expose exposeDecl;

  Future call(AngelBase app) async {
    this.app = app;

    // Load global expose decl
    ClassMirror classMirror = reflectClass(this.runtimeType);

    for (InstanceMirror metadatum in classMirror.metadata) {
      if (metadatum.reflectee is Expose) {
        exposeDecl = metadatum.reflectee;
        break;
      }
    }

    if (exposeDecl == null) {
      throw new Exception(
          "All controllers must carry an @Expose() declaration.");
    }

    app.use(exposeDecl.path, generateRoutable(classMirror));
    TypeMirror typeMirror = reflectType(this.runtimeType);
    String name = exposeDecl.as;

    if (name == null || name.isEmpty)
      name = MirrorSystem.getName(typeMirror.simpleName);

    app.controllers[name] = this;
  }

  _callback(InstanceMirror instanceMirror, Routable routable, List handlers) {
    return (Symbol key, MethodMirror methodMirror) {
      if (methodMirror.isRegularMethod &&
          key != #toString &&
          key != #noSuchMethod &&
          key != #call &&
          key != #equals &&
          key != #==) {
        InstanceMirror exposeMirror = methodMirror.metadata.firstWhere(
            (mirror) => mirror.reflectee is Expose,
            orElse: () => null);

        if (exposeMirror != null) {
          RequestHandler handler =
              (RequestContext req, ResponseContext res) async {
            List args = [];

            // Load parameters, and execute
            for (int i = 0; i < methodMirror.parameters.length; i++) {
              ParameterMirror parameter = methodMirror.parameters[i];
              if (parameter.type.reflectedType == RequestContext)
                args.add(req);
              else if (parameter.type.reflectedType == ResponseContext)
                args.add(res);
              else {
                String name = MirrorSystem.getName(parameter.simpleName);
                var arg = req.params[name];

                if (arg == null) {
                  if (parameter.type.reflectedType != dynamic) {
                    try {
                      arg = app.container.make(parameter.type.reflectedType);
                      if (arg != null) {
                        args.add(arg);
                        continue;
                      }
                    } catch (e) {
                      //
                    }
                  }

                  if (!exposeMirror.reflectee.allowNull.contain(name))
                    throw new AngelHttpException.BadRequest(
                        message: "Missing parameter '$name'");
                } else
                  args.add(arg);
              }
            }

            return await instanceMirror.invoke(key, args).reflectee;
          };

          final middleware = []
            ..addAll(handlers)
            ..addAll(exposeMirror.reflectee.middleware);

          final route = routable.addRoute(exposeMirror.reflectee.method,
              exposeMirror.reflectee.path, handler,
              middleware: middleware);

          String name = exposeMirror.reflectee.as;

          if (name == null || name.isEmpty) name = MirrorSystem.getName(key);

          routeMappings[name] = route;
        }
      }
    };
  }

  Routable generateRoutable(ClassMirror classMirror) {
    final routable = new Routable(debug: true);
    final handlers = []..addAll(exposeDecl.middleware)..addAll(middleware);

    InstanceMirror instanceMirror = reflect(this);
    final callback = _callback(instanceMirror, routable, handlers);
    classMirror.instanceMembers.forEach(callback);

    return routable;
  }
}
