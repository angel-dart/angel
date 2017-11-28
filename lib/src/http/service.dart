library angel_framework.http.service;

import 'dart:async';
import 'package:angel_framework/src/http/response_context.dart';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:merge_map/merge_map.dart';
import '../util.dart';
import 'angel_base.dart';
import 'hooked_service.dart' show HookedService;
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

  static const String viaRest = "rest";
  static const String viaWebsocket = "websocket";
  static const String viaGraphQL = "graphql";

  /// Represents a request via REST.
  static const Providers rest = const Providers(viaRest);

  /// Represents a request over WebSockets.
  static const Providers websocket = const Providers(viaWebsocket);

  /// Represents a request parsed from GraphQL.
  static const Providers graphql = const Providers(viaGraphQL);

  @override
  bool operator ==(other) => other is Providers && other.via == via;

  @override
  String toString() {
    return 'via:$via';
  }
}

/// A front-facing interface that can present data to and operate on data on behalf of the user.
///
/// Heavily inspired by FeathersJS. <3
class Service extends Routable {
  /// A [List] of keys that services should ignore, should they see them in the query.
  static const List<String> specialQueryKeys = const [
    r'$limit',
    r'$sort',
    'page',
    'token'
  ];

  /// The [Angel] app powering this service.
  AngelBase app;

  /// Closes this service, including any database connections or stream controllers.
  Future close() async {}

  /// Retrieves all resources.
  Future index([Map params]) {
    throw new AngelHttpException.methodNotAllowed();
  }

  /// Retrieves the desired resource.
  Future read(id, [Map params]) {
    throw new AngelHttpException.methodNotAllowed();
  }

  /// Creates a resource.
  Future create(data, [Map params]) {
    throw new AngelHttpException.methodNotAllowed();
  }

  /// Modifies a resource.
  Future modify(id, data, [Map params]) {
    throw new AngelHttpException.methodNotAllowed();
  }

  /// Overwrites a resource.
  Future update(id, data, [Map params]) {
    throw new AngelHttpException.methodNotAllowed();
  }

  /// Removes the given resource.
  Future remove(id, [Map params]) {
    throw new AngelHttpException.methodNotAllowed();
  }

  /// Transforms an [id] string into one acceptable by a service.
  toId(String id) {
    if (id == 'null' || id == null)
      return null;
    else
      return id;
  }

  /// Generates RESTful routes pointing to this class's methods.
  void addRoutes() {
    Map restProvider = {'provider': Providers.rest};

    // Add global middleware if declared on the instance itself
    Middleware before = getAnnotation(this, Middleware);
    final handlers = [];

    if (before != null) handlers.addAll(before.handlers);

    Middleware indexMiddleware = getAnnotation(this.index, Middleware);
    get('/', (req, res) async {
      return await this.index(mergeMap([
        {'query': req.query},
        restProvider,
        req.serviceParams
      ]));
    },
        middleware: []
          ..addAll(handlers)
          ..addAll((indexMiddleware == null) ? [] : indexMiddleware.handlers));

    Middleware createMiddleware = getAnnotation(this.create, Middleware);
    post('/', (req, ResponseContext res) async {
      var r = await this.create(
          await req.lazyBody(),
          mergeMap([
            {'query': req.query},
            restProvider,
            req.serviceParams
          ]));
      res.statusCode = 201;
      return r;
    },
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (createMiddleware == null) ? [] : createMiddleware.handlers));

    Middleware readMiddleware = getAnnotation(this.read, Middleware);

    get(
        '/:id',
        (req, res) async => await this.read(
            toId(req.params['id']),
            mergeMap([
              {'query': req.query},
              restProvider,
              req.serviceParams
            ])),
        middleware: []
          ..addAll(handlers)
          ..addAll((readMiddleware == null) ? [] : readMiddleware.handlers));

    Middleware modifyMiddleware = getAnnotation(this.modify, Middleware);
    patch(
        '/:id',
        (req, res) async => await this.modify(
            toId(req.params['id']),
            await req.lazyBody(),
            mergeMap([
              {'query': req.query},
              restProvider,
              req.serviceParams
            ])),
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (modifyMiddleware == null) ? [] : modifyMiddleware.handlers));

    Middleware updateMiddleware = getAnnotation(this.update, Middleware);
    post(
        '/:id',
        (req, res) async => await this.update(
            toId(req.params['id']),
            await req.lazyBody(),
            mergeMap([
              {'query': req.query},
              restProvider,
              req.serviceParams
            ])),
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (updateMiddleware == null) ? [] : updateMiddleware.handlers));
    put(
        '/:id',
        (req, res) async => await this.update(
            toId(req.params['id']),
            await req.lazyBody(),
            mergeMap([
              {'query': req.query},
              restProvider,
              req.serviceParams
            ])),
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (updateMiddleware == null) ? [] : updateMiddleware.handlers));

    Middleware removeMiddleware = getAnnotation(this.remove, Middleware);
    delete(
        '/',
        (req, res) async => await this.remove(
            null,
            mergeMap([
              {'query': req.query},
              restProvider,
              req.serviceParams
            ])),
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (removeMiddleware == null) ? [] : removeMiddleware.handlers));
    delete(
        '/:id',
        (req, res) async => await this.remove(
            toId(req.params['id']),
            mergeMap([
              {'query': req.query},
              restProvider,
              req.serviceParams
            ])),
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (removeMiddleware == null) ? [] : removeMiddleware.handlers));

    // REST compliance
    put('/', () => throw new AngelHttpException.notFound());
    patch('/', () => throw new AngelHttpException.notFound());
  }

  /// Invoked when this service is wrapped within a [HookedService].
  void onHooked(HookedService hookedService) {}
}
