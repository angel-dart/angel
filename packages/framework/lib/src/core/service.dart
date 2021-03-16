library angel_framework.http.service;

import 'dart:async';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:merge_map/merge_map.dart';
import 'package:quiver/core.dart';
import '../util.dart';
import 'anonymous_service.dart';
import 'hooked_service.dart' show HookedService;
import 'metadata.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'routable.dart';
import 'server.dart';

/// Indicates how the service was accessed.
///
/// This will be passed to the `params` object in a service method.
/// When requested on the server side, this will be null.
class Providers {
  /// The transport through which the client is accessing this service.
  final String via;

  const Providers(this.via);

  static const String viaRest = "rest";
  static const String viaWebsocket = "websocket";
  static const String viaGraphQL = "graphql";

  /// Represents a request via REST.
  static const Providers rest = Providers(viaRest);

  /// Represents a request over WebSockets.
  static const Providers websocket = Providers(viaWebsocket);

  /// Represents a request parsed from GraphQL.
  static const Providers graphQL = Providers(viaGraphQL);

  @override
  int get hashCode => hashObjects([via]);

  @override
  bool operator ==(other) => other is Providers && other.via == via;

  Map<String, String> toJson() {
    return {'via': via};
  }

  @override
  String toString() {
    return 'via:$via';
  }
}

/// A front-facing interface that can present data to and operate on data on behalf of the user.
///
/// Heavily inspired by FeathersJS. <3
class Service<Id, Data> extends Routable {
  /// A [List] of keys that services should ignore, should they see them in the query.
  static const List<String> specialQueryKeys = <String>[
    r'$limit',
    r'$sort',
    'page',
    'token'
  ];

  /// Handlers that must run to ensure this service's functionality.
  List<RequestHandler> get bootstrappers => [];

  /// The [Angel] app powering this service.
  Angel app;

  /// Closes this service, including any database connections or stream controllers.
  void close() {}

  /// An optional [readData] function can be passed to handle non-map/non-json bodies.
  Service({FutureOr<Data> Function(RequestContext, ResponseContext) readData}) {
    _readData = readData ??
        (req, res) {
          if (req.bodyAsObject is! Data) {
            throw AngelHttpException.badRequest(
                message:
                    'Invalid request body. Expected $Data; found ${req.bodyAsObject} instead.');
          } else {
            return req.bodyAsObject as Data;
          }
        };
  }

  FutureOr<Data> Function(RequestContext, ResponseContext) _readData;

  /// A [Function] that reads the request body and converts it into [Data].
  FutureOr<Data> Function(RequestContext, ResponseContext) get readData =>
      _readData;

  /// Retrieves the first object from the result of calling [index] with the given [params].
  ///
  /// If the result of [index] is `null`, OR an empty [Iterable], a 404 `AngelHttpException` will be thrown.
  ///
  /// If the result is both non-null and NOT an [Iterable], it will be returned as-is.
  ///
  /// If the result is a non-empty [Iterable], [findOne] will return `it.first`, where `it` is the aforementioned [Iterable].
  ///
  /// A custom [errorMessage] may be provided.
  Future<Data> findOne(
      [Map<String, dynamic> params,
      String errorMessage = 'No record was found matching the given query.']) {
    return index(params).then((result) {
      if (result == null) {
        throw AngelHttpException.notFound(message: errorMessage);
      } else {
        if (result.isEmpty) {
          throw AngelHttpException.notFound(message: errorMessage);
        } else {
          return result.first;
        }
      }
    });
  }

  /// Retrieves all resources.
  Future<List<Data>> index([Map<String, dynamic> params]) {
    throw AngelHttpException.methodNotAllowed();
  }

  /// Retrieves the desired resource.
  Future<Data> read(Id id, [Map<String, dynamic> params]) {
    throw AngelHttpException.methodNotAllowed();
  }

  /// Reads multiple resources at once.
  ///
  /// Service implementations should override this to ensure data is fetched within a
  /// single round trip.
  Future<List<Data>> readMany(List<Id> ids, [Map<String, dynamic> params]) {
    return Future.wait(ids.map((id) => read(id, params)));
  }

  /// Creates a resource.
  Future<Data> create(Data data, [Map<String, dynamic> params]) {
    throw AngelHttpException.methodNotAllowed();
  }

  /// Modifies a resource.
  Future<Data> modify(Id id, Data data, [Map<String, dynamic> params]) {
    throw AngelHttpException.methodNotAllowed();
  }

  /// Overwrites a resource.
  Future<Data> update(Id id, Data data, [Map<String, dynamic> params]) {
    throw AngelHttpException.methodNotAllowed();
  }

  /// Removes the given resource.
  Future<Data> remove(Id id, [Map<String, dynamic> params]) {
    throw AngelHttpException.methodNotAllowed();
  }

  /// Creates an [AnonymousService] that wraps over this one, and maps input and output
  /// using two converter functions.
  ///
  /// Handy utility for handling data in a type-safe manner.
  Service<Id, U> map<U>(U Function(Data) encoder, Data Function(U) decoder,
      {FutureOr<U> Function(RequestContext, ResponseContext) readData}) {
    readData ??= (req, res) async {
      var inner = await this.readData(req, res);
      return encoder(inner);
    };

    return AnonymousService<Id, U>(
      readData: readData,
      index: ([params]) {
        return index(params).then((it) => it.map(encoder).toList());
      },
      read: (id, [params]) {
        return read(id, params).then(encoder);
      },
      create: (data, [params]) {
        return create(decoder(data), params).then(encoder);
      },
      modify: (id, data, [params]) {
        return modify(id, decoder(data), params).then(encoder);
      },
      update: (id, data, [params]) {
        return update(id, decoder(data), params).then(encoder);
      },
      remove: (id, [params]) {
        return remove(id, params).then(encoder);
      },
    );
  }

  /// Transforms an [id] (whether it is a String, num, etc.) into one acceptable by a service.
  ///
  /// The single type argument, [T], is used to determine how to parse the [id].
  ///
  /// For example, `parseId<bool>` attempts to parse the value as a [bool].
  static T parseId<T>(id) {
    if (id == 'null' || id == null) {
      return null;
    } else if (T == String) {
      return id.toString() as T;
    } else if (T == int) {
      return int.parse(id.toString()) as T;
    } else if (T == bool) {
      return (id == true || id?.toString() == 'true') as T;
    } else if (T == double) {
      return double.parse(id.toString()) as T;
    } else if (T == num) {
      return num.parse(id.toString()) as T;
    } else {
      return id as T;
    }
  }

  /// Generates RESTful routes pointing to this class's methods.
  void addRoutes([Service service]) {
    _addRoutesInner(service ?? this, bootstrappers);
  }

  void _addRoutesInner(Service service, Iterable<RequestHandler> handlerss) {
    var restProvider = {'provider': Providers.rest};
    var handlers = List<RequestHandler>.from(handlerss);

    // Add global middleware if declared on the instance itself
    Middleware before =
        getAnnotation<Middleware>(service, app.container.reflector);

    if (before != null) handlers.addAll(before.handlers);

    Middleware indexMiddleware =
        getAnnotation<Middleware>(service.index, app.container.reflector);
    get('/', (req, res) {
      return this.index(mergeMap([
        {'query': req.queryParameters},
        restProvider,
        req.serviceParams
      ]));
    },
        middleware: <RequestHandler>[]
          ..addAll(handlers)
          ..addAll((indexMiddleware == null) ? [] : indexMiddleware.handlers));

    Middleware createMiddleware =
        getAnnotation<Middleware>(service.create, app.container.reflector);
    post('/', (req, ResponseContext res) {
      return req.parseBody().then((_) async {
        return await this
            .create(
                await readData(req, res),
                mergeMap([
                  {'query': req.queryParameters},
                  restProvider,
                  req.serviceParams
                ]))
            .then((r) {
          res.statusCode = 201;
          return r;
        });
      });
    },
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (createMiddleware == null) ? [] : createMiddleware.handlers));

    Middleware readMiddleware =
        getAnnotation<Middleware>(service.read, app.container.reflector);

    get('/:id', (req, res) {
      return this.read(
          parseId<Id>(req.params['id']),
          mergeMap([
            {'query': req.queryParameters},
            restProvider,
            req.serviceParams
          ]));
    },
        middleware: []
          ..addAll(handlers)
          ..addAll((readMiddleware == null) ? [] : readMiddleware.handlers));

    Middleware modifyMiddleware =
        getAnnotation<Middleware>(service.modify, app.container.reflector);
    patch('/:id', (req, res) {
      return req.parseBody().then((_) async {
        return await this.modify(
            parseId<Id>(req.params['id']),
            await readData(req, res),
            mergeMap([
              {'query': req.queryParameters},
              restProvider,
              req.serviceParams
            ]));
      });
    },
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (modifyMiddleware == null) ? [] : modifyMiddleware.handlers));

    Middleware updateMiddleware =
        getAnnotation<Middleware>(service.update, app.container.reflector);
    post('/:id', (req, res) {
      return req.parseBody().then((_) async {
        return await this.update(
            parseId<Id>(req.params['id']),
            await readData(req, res),
            mergeMap([
              {'query': req.queryParameters},
              restProvider,
              req.serviceParams
            ]));
      });
    },
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (updateMiddleware == null) ? [] : updateMiddleware.handlers));
    put('/:id', (req, res) {
      return req.parseBody().then((_) async {
        return await this.update(
            parseId<Id>(req.params['id']),
            await readData(req, res),
            mergeMap([
              {'query': req.queryParameters},
              restProvider,
              req.serviceParams
            ]));
      });
    },
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (updateMiddleware == null) ? [] : updateMiddleware.handlers));

    Middleware removeMiddleware =
        getAnnotation<Middleware>(service.remove, app.container.reflector);
    delete('/', (req, res) {
      return this.remove(
          null,
          mergeMap([
            {'query': req.queryParameters},
            restProvider,
            req.serviceParams
          ]));
    },
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (removeMiddleware == null) ? [] : removeMiddleware.handlers));
    delete('/:id', (req, res) {
      return this.remove(
          parseId<Id>(req.params['id']),
          mergeMap([
            {'query': req.queryParameters},
            restProvider,
            req.serviceParams
          ]));
    },
        middleware: []
          ..addAll(handlers)
          ..addAll(
              (removeMiddleware == null) ? [] : removeMiddleware.handlers));

    // REST compliance
    put('/', (req, res) => throw AngelHttpException.notFound());
    patch('/', (req, res) => throw AngelHttpException.notFound());
  }

  /// Invoked when this service is wrapped within a [HookedService].
  void onHooked(HookedService hookedService) {}
}
