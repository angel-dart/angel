part of angel_framework.http;

/// Wraps another service in a service that broadcasts events on actions.
class HookedService extends Service {
  final Service inner;

  HookedServiceEventDispatcher beforeIndexed =
  new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher beforeRead = new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher beforeCreated =
  new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher beforeModified =
  new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher beforeUpdated =
  new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher beforeRemoved =
  new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher afterIndexed =
  new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher afterRead = new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher afterCreated =
  new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher afterModified =
  new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher afterUpdated =
  new HookedServiceEventDispatcher();
  HookedServiceEventDispatcher afterRemoved =
  new HookedServiceEventDispatcher();

  HookedService(Service this.inner) : super() {}

  @override
  Future<List> index([Map params]) async {
    HookedServiceEvent before = await beforeIndexed._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.INDEXED,
            params: params));
    if (before._canceled) {
      HookedServiceEvent after = await beforeIndexed._emit(
          new HookedServiceEvent._base(inner, HookedServiceEvent.INDEXED,
              params: params, result: before.result));
      return after.result;
    }

    List result = await inner.index(params);
    HookedServiceEvent after = await afterIndexed._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.INDEXED,
            params: params, result: result));
    return after.result;
  }

  @override
  Future read(id, [Map params]) async {
    HookedServiceEvent before = await beforeRead._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.READ,
            id: id, params: params));

    if (before._canceled) {
      HookedServiceEvent after = await afterRead._emit(
          new HookedServiceEvent._base(inner, HookedServiceEvent.READ,
              id: id, params: params, result: before.result));
      return after.result;
    }

    var result = await inner.read(id, params);
    HookedServiceEvent after = await afterRead._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.READ,
            id: id, params: params, result: result));
    return after.result;
  }

  @override
  Future create(data, [Map params]) async {
    HookedServiceEvent before = await beforeCreated._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.CREATED,
            data: data, params: params));

    if (before._canceled) {
      HookedServiceEvent after = await afterCreated._emit(
          new HookedServiceEvent._base(inner, HookedServiceEvent.CREATED,
              data: data, params: params, result: before.result));
      return after.result;
    }

    var result = await inner.create(data, params);
    HookedServiceEvent after = await afterCreated._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.CREATED,
            data: data, params: params, result: result));
    return after.result;
  }

  @override
  Future modify(id, data, [Map params]) async {
    HookedServiceEvent before = await beforeModified._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.MODIFIED,
            id: id, data: data, params: params));

    if (before._canceled) {
      HookedServiceEvent after = await afterModified._emit(
          new HookedServiceEvent._base(inner, HookedServiceEvent.MODIFIED,
              id: id, data: data, params: params, result: before.result));
      return after.result;
    }

    var result = await inner.modify(id, data, params);
    HookedServiceEvent after = await afterModified._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.MODIFIED,
            id: id, data: data, params: params, result: result));
    return after.result;
  }

  @override
  Future update(id, data, [Map params]) async {
    HookedServiceEvent before = await beforeUpdated._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.UPDATED,
            id: id, data: data, params: params));

    if (before._canceled) {
      HookedServiceEvent after = await afterUpdated._emit(
          new HookedServiceEvent._base(inner, HookedServiceEvent.UPDATED,
              id: id, data: data, params: params, result: before.result));
      return after.result;
    }

    var result = await inner.update(id, data, params);
    HookedServiceEvent after = await afterUpdated._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.UPDATED,
            id: id, data: data, params: params, result: result));
    return after.result;
  }

  @override
  Future remove(id, [Map params]) async {
    HookedServiceEvent before = await beforeRemoved._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.REMOVED,
            id: id, params: params));

    if (before._canceled) {
      HookedServiceEvent after = await afterRemoved._emit(
          new HookedServiceEvent._base(inner, HookedServiceEvent.REMOVED,
              id: id, params: params, result: before.result));
      return after.result;
    }

    var result = await inner.remove(id, params);
    HookedServiceEvent after = await afterRemoved._emit(
        new HookedServiceEvent._base(inner, HookedServiceEvent.REMOVED,
            id: id, params: params, result: result));
    return after.result;
  }
}

/// Fired when a hooked service is invoked.
class HookedServiceEvent {
  static const String INDEXED = "indexed";
  static const String READ = "read";
  static const String CREATED = "created";
  static const String MODIFIED = "modified";
  static const String UPDATED = "updated";
  static const String REMOVED = "removed";

  /// Use this to end processing of an event.
  void cancel(result) {
    _canceled = true;
    _result = result;
  }

  bool _canceled = false;
  String _eventName;
  var _id;
  var data;
  Map _params;
  var _result;

  String get eventName => _eventName;

  get id => _id;

  Map get params => _params;

  get result => _result;

  /// The inner service whose method was hooked.
  Service service;

  HookedServiceEvent._base(Service this.service, String this._eventName,
      {id, this.data, Map params, result}) {
    _id = id;
    _params = params ?? {};
    _result = result;
  }
}

/// Triggered on a hooked service event.
typedef Future HookedServiceEventListener(HookedServiceEvent event);

/// Can be listened to, but events may be canceled.
class HookedServiceEventDispatcher {
  List<HookedServiceEventListener> listeners = [];

  /// Fires an event, and returns it once it is either canceled, or all listeners have run.
  Future<HookedServiceEvent> _emit(HookedServiceEvent event) async {
    for (var listener in listeners) {
      await listener(event);

      if (event._canceled) return event;
    }

    return event;
  }

  /// Registers the listener to be called whenever an event is triggered.
  void listen(HookedServiceEventListener listener) {
    listeners.add(listener);
  }
}
