library angel_framework.http.service;

import 'dart:async';
import 'package:merge_map/merge_map.dart';
import '../util.dart';
import 'angel_base.dart';
import 'angel_http_exception.dart';
import 'metadata.dart';
import 'routable.dart';

/// Indicates how the service was accessed.
///
/// This will be passed to the `params` object in a service method.
/// When requested on the server side, this will be null.
class Providers {
  /// The transport through which the client is accessing this service.
  final String via;

  const Providers(String this.via);

  static const String VIA_REST = "rest";
  static const String VIA_WEBSOCKET = "websocket";

  /// Represents a request via REST.
  static final Providers REST = const Providers(VIA_REST);

  /// Represents a request over WebSockets.
  static final Providers WEBSOCKET = const Providers(VIA_WEBSOCKET);
}

/// A front-facing interface that can present data to and operate on data on behalf of the user.
///
/// Heavily inspired by FeathersJS. <3
class Service extends Routable {
  /// The [Angel] app powering this service.
  AngelBase app;

  /// Retrieves all resources.
  Future<List> index([Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  /// Retrieves the desired resource.
  Future read(id, [Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  /// Creates a resource.
  Future create(data, [Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  /// Modifies a resource.
  Future modify(id, data, [Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  /// Overwrites a resource.
  Future update(id, data, [Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  /// Removes the given resource.
  Future remove(id, [Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  void addRoutes() {
    Map restProvider = {'provider': Providers.REST};

    // Add global middleware if declared on the instance itself
    Middleware before = getAnnotation(this, Middleware);
    final handlers = [];

    if (before != null) handlers.addAll(before.handlers);

    Middleware indexMiddleware = getAnnotation(this.index, Middleware);
    get('/', (req, res) async {
      return await this.index(mergeMap([req.query, restProvider]));
    },
        middleware: []
          ..addAll(handlers)
          ..addAll((indexMiddleware == null) ? [] : indexMiddleware.handlers));

    Middleware createMiddleware = getAnnotation(this.create, Middleware);
    post('/', (req, res) async => await this.create(req.body, restProvider),
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (createMiddleware == null) ? [] : createMiddleware.handlers));

    Middleware readMiddleware = getAnnotation(this.read, Middleware);

    get(
        '/:id',
        (req, res) async => await this
        .read(req.params['id'], mergeMap([req.query, restProvider])),
        middleware: []
          ..addAll(handlers)
          ..addAll((readMiddleware == null) ? [] : readMiddleware.handlers));

    Middleware modifyMiddleware = getAnnotation(this.modify, Middleware);
    patch(
        '/:id',
        (req, res) async =>
    await this.modify(req.params['id'], req.body, restProvider),
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (modifyMiddleware == null) ? [] : modifyMiddleware.handlers));

    Middleware updateMiddleware = getAnnotation(this.update, Middleware);
    post(
        '/:id',
        (req, res) async =>
    await this.update(req.params['id'], req.body, restProvider),
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (updateMiddleware == null) ? [] : updateMiddleware.handlers));

    Middleware removeMiddleware = getAnnotation(this.remove, Middleware);
    delete(
        '/:id',
        (req, res) async => await this
        .remove(req.params['id'], mergeMap([req.query, restProvider])),
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (removeMiddleware == null) ? [] : removeMiddleware.handlers));

    normalize();
  }
}
