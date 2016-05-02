part of angel_framework.http;

/// Wraps another service in a service that fires events on actions.
class HookedService extends Service {
  StreamController<List> _onIndexed = new StreamController<List>();
  StreamController _onRead = new StreamController();
  StreamController _onCreated = new StreamController();
  StreamController _onModified = new StreamController();
  StreamController _onUpdated = new StreamController();
  StreamController _onRemoved = new StreamController();

  Stream<List> get onIndexed => _onIndexed.stream;

  Stream get onRead => _onRead.stream;

  Stream get onCreated => _onCreated.stream;

  Stream get onModified => _onModified.stream;

  Stream get onUpdated => _onUpdated.stream;

  Stream get onRemoved => _onRemoved.stream;

  final Service inner;

  HookedService(Service this.inner);


  @override
  Future<List> index([Map params]) async {
    List indexed = await inner.index(params);
    _onIndexed.add(indexed);
    return indexed;
  }


  @override
  Future read(id, [Map params]) async {
    var retrieved = await inner.read(id, params);
    _onRead.add(retrieved);
    return retrieved;
  }


  @override
  Future create(Map data, [Map params]) async {
    var created = await inner.create(data, params);
    _onCreated.add(created);
    return created;
  }

  @override
  Future modify(id, Map data, [Map params]) async {
    var modified = await inner.modify(id, data, params);
    _onUpdated.add(modified);
    return modified;
  }


  @override
  Future update(id, Map data, [Map params]) async {
    var updated = await inner.update(id, data, params);
    _onUpdated.add(updated);
    return updated;
  }

  @override
  Future remove(id, [Map params]) async {
    var removed = await inner.remove(id, params);
    _onRemoved.add(removed);
    return removed;
  }
}