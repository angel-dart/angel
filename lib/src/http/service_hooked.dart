part of angel_framework.http;

/// Wraps another service in a service that broadcasts events on actions.
class HookedService extends Service {
  StreamController<HookedServiceEvent> _beforeIndexed = new StreamController<HookedServiceEvent>.broadcast();
  StreamController<HookedServiceEvent> _beforeRead = new StreamController.broadcast();
  StreamController<HookedServiceEvent> _beforeCreated = new StreamController.broadcast();
  StreamController<HookedServiceEvent> _beforeModified = new StreamController.broadcast();
  StreamController<HookedServiceEvent> _beforeUpdated = new StreamController.broadcast();
  StreamController<HookedServiceEvent> _beforeRemoved = new StreamController.broadcast();

  Stream<HookedServiceEvent> get beforeIndexed => _beforeIndexed.stream;

  Stream<HookedServiceEvent> get beforeRead => _beforeRead.stream;

  Stream<HookedServiceEvent> get beforeCreated => _beforeCreated.stream;

  Stream<HookedServiceEvent> get beforeModified => _beforeModified.stream;

  Stream<HookedServiceEvent> get beforeUpdated => _beforeUpdated.stream;

  Stream<HookedServiceEvent> get beforeRemoved => _beforeRemoved.stream;
  
  StreamController<HookedServiceEvent> _afterIndexed = new StreamController<HookedServiceEvent>.broadcast();
  StreamController<HookedServiceEvent> _afterRead = new StreamController<HookedServiceEvent>.broadcast();
  StreamController<HookedServiceEvent> _afterCreated = new StreamController<HookedServiceEvent>.broadcast();
  StreamController<HookedServiceEvent> _afterModified = new StreamController<HookedServiceEvent>.broadcast();
  StreamController<HookedServiceEvent> _afterUpdated = new StreamController<HookedServiceEvent>.broadcast();
  StreamController<HookedServiceEvent> _afterRemoved = new StreamController<HookedServiceEvent>.broadcast();

  Stream<HookedServiceEvent> get afterIndexed => _afterIndexed.stream;

  Stream<HookedServiceEvent> get afterRead => _afterRead.stream;

  Stream<HookedServiceEvent> get afterCreated => _afterCreated.stream;

  Stream<HookedServiceEvent> get afterModified => _afterModified.stream;

  Stream<HookedServiceEvent> get afterUpdated => _afterUpdated.stream;

  Stream<HookedServiceEvent> get afterRemoved => _afterRemoved.stream;

  final Service inner;

  HookedService(Service this.inner);


  @override
  Future<List> index([Map params]) async {
    HookedServiceEvent before = new HookedServiceEvent._base(inner, params: params);
    _beforeIndexed.add(before);

    if (before._canceled) {
      HookedServiceEvent after = new HookedServiceEvent._base(inner, params: params, result: before.result);
      _afterIndexed.add(after);
      return before.result;
    }

    List result = await inner.index(params);
    HookedServiceEvent after = new HookedServiceEvent._base(inner, params: params, result: result);
    _afterIndexed.add(after);
    return result;
  }


  @override
  Future read(id, [Map params]) async {
    var retrieved = await inner.read(id, params);
    _afterRead.add(retrieved);
    return retrieved;
  }


  @override
  Future create(data, [Map params]) async {
    var created = await inner.create(data, params);
    _afterCreated.add(created);
    return created;
  }

  @override
  Future modify(id, data, [Map params]) async {
    var modified = await inner.modify(id, data, params);
    _afterUpdated.add(modified);
    return modified;
  }


  @override
  Future update(id, data, [Map params]) async {
    var updated = await inner.update(id, data, params);
    _afterUpdated.add(updated);
    return updated;
  }

  @override
  Future remove(id, [Map params]) async {
    var removed = await inner.remove(id, params);
    _afterRemoved.add(removed);
    return removed;
  }
}

/// Fired when a hooked service is invoked.
class HookedServiceEvent {
  /// Use this to end processing of an event.
  void cancel(result) {
    _canceled = true;
    _result = result;
  }

  bool _canceled = false;
  var id;
  var data;
  Map params;
  var _result;
  get result => _result;
  /// The inner service whose method was hooked.
  Service service;

  HookedServiceEvent._base(Service this.service, {this.id, this.data, Map this.params: const{}, result}) {
    _result = result;
  }
}