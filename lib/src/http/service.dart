part of angel_framework.http;

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
  Angel app;

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

  Service() : super() {
    Map restProvider = {'provider': Providers.REST};

    Middleware indexMiddleware = _getAnnotation(this.index, Middleware);
    get('/', (req, res) async {
      return await this.index(mergeMap([req.query, restProvider]));
    }, middleware: (indexMiddleware == null) ? [] : indexMiddleware.handlers);

    Middleware createMiddleware = _getAnnotation(this.create, Middleware);
    post('/', (req, res) async => await this.create(req.body, restProvider),
        middleware:
            (createMiddleware == null) ? [] : createMiddleware.handlers);

    Middleware readMiddleware = _getAnnotation(this.read, Middleware);

    get(
        '/:id',
        (req, res) async => await this
            .read(req.params['id'], mergeMap([req.query, restProvider])),
        middleware: (readMiddleware == null) ? [] : readMiddleware.handlers);

    Middleware modifyMiddleware = _getAnnotation(this.modify, Middleware);
    patch(
        '/:id',
        (req, res) async =>
            await this.modify(req.params['id'], req.body, restProvider),
        middleware:
            (modifyMiddleware == null) ? [] : modifyMiddleware.handlers);

    Middleware updateMiddleware = _getAnnotation(this.update, Middleware);
    post(
        '/:id',
        (req, res) async =>
            await this.update(req.params['id'], req.body, restProvider),
        middleware:
            (updateMiddleware == null) ? [] : updateMiddleware.handlers);

    Middleware removeMiddleware = _getAnnotation(this.remove, Middleware);
    delete(
        '/:id',
        (req, res) async => await this
            .remove(req.params['id'], mergeMap([req.query, restProvider])),
        middleware:
            (removeMiddleware == null) ? [] : removeMiddleware.handlers);
  }
}
