part of angel_framework.http;

/// A data store exposed to the Internet.
class Service extends Routable {
  /// The [Angel] app powering this service.
  Angel app;

  /// Retrieves all resources.
  Future<List> index([Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  /// Retrieves the desired resource.
  Future<Object> read(id, [Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  /// Creates a resource.
  Future<Object> create(Map data, [Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  /// Modifies a resource.
  Future<Object> modify(id, Map data, [Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  /// Overwrites a resource.
  Future<Object> update(id, Map data, [Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  /// Removes the given resource.
  Future<Object> remove(id, [Map params]) {
    throw new AngelHttpException.MethodNotAllowed();
  }

  Service() : super() {
    get('/', (req, res) async => await this.index(req.query));

    post('/', (req, res) async => await this.create(req.body));

    get('/:id', (req, res) async =>
    await this.read(req.params['id'], req.query));

    patch('/:id', (req, res) async => await this.modify(
        req.params['id'], req.body));

    post('/:id', (req, res) async => await this.update(
        req.params['id'], req.body));

    delete('/:id', (req, res) async => await this.remove(req.params['id'], req.query));
  }
}