part of angel_framework.http;

class Providers {
  final String via;

  const Providers._base(String this.via);

  static final Providers SERVER = const Providers._base('server_side');
  static final Providers REST = const Providers._base('rest');
  static final Providers WEBSOCKET = const Providers._base('websocket');
}

/// A data store exposed to the Internet.
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

    get('/', (req, res) async {
      return await this.index(mergeMap([req.query, restProvider]));
    });

    post('/', (req, res) async => await this.create(req.body, restProvider));

    get('/:id', (req, res) async =>
    await this.read(req.params['id'], mergeMap([req.query, restProvider])));

    patch('/:id', (req, res) async => await this.modify(
        req.params['id'], req.body, restProvider));

    post('/:id', (req, res) async => await this.update(
        req.params['id'], req.body, restProvider));

    delete('/:id', (req, res) async => await this.remove(
        req.params['id'], mergeMap([req.query, restProvider])));
  }
}