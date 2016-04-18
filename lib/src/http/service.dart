part of angel_framework.http;

/// A data store exposed to the Internet.
class Service extends Routable {

  /// Retrieves all resources.
  Future<List> index([Map params]) {
    throw new MethodNotAllowedError('find');
  }

  /// Retrieves the desired resource.
  Future<Object> read(id, [Map params]) {
    throw new MethodNotAllowedError('get');
  }

  /// Creates a resource.
  Future<Object> create(Map data, [Map params]) {
    throw new MethodNotAllowedError('create');
  }

  /// Modifies a resource.
  Future<Object> update(id, Map data, [Map params]) {
    throw new MethodNotAllowedError('update');
  }

  /// Removes the given resource.
  Future<Object> remove(id, [Map params]) {
    throw new MethodNotAllowedError('remove');
  }

  Service() : super() {
    get('/', (req, res) async => res.json(await this.index(req.query)));
    get('/:id', (req, res) async =>
        res.json(await this.read(req.params['id'], req.query)));
    post('/', (req, res) async => res.json(await this.create(req.body))g);
    post('/:id', (req, res) async =>
        res.json(await this.update(req.params['id'], req.body)));
    delete('/:id', (req, res) async =>
        res.json(await this.remove(req.params['id'], req.body)));
  }
}

/// Thrown when an unimplemented method is called.
class MethodNotAllowedError extends Error {
  /// The action that threw the error.
  ///
  /// Ex. 'get', 'remove'
  String action;

  /// A description of this error.
  String get error => 'This service does not support the "$action" action.';

  MethodNotAllowedError(String this.action);
}