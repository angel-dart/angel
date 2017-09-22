library angel_framework.http;

import 'dart:async';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:merge_map/merge_map.dart';
import '../util.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'metadata.dart';
import 'service.dart';

/// Wraps another service in a service that broadcasts events on actions.
class HookedService extends Service {
  final List<StreamController<HookedServiceEvent>> _ctrl = [];

  /// Tbe service that is proxied by this hooked one.
  final Service inner;

  final HookedServiceEventDispatcher beforeIndexed =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher beforeRead =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher beforeCreated =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher beforeModified =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher beforeUpdated =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher beforeRemoved =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher afterIndexed =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher afterRead =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher afterCreated =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher afterModified =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher afterUpdated =
      new HookedServiceEventDispatcher();
  final HookedServiceEventDispatcher afterRemoved =
      new HookedServiceEventDispatcher();

  HookedService(Service this.inner) {
    // Clone app instance
    if (inner.app != null) this.app = inner.app;
  }

  RequestContext _getRequest(Map params) {
    if (params == null) return null;
    return params['__requestctx'];
  }

  ResponseContext _getResponse(Map params) {
    if (params == null) return null;
    return params['__responsectx'];
  }

  Map _stripReq(Map params) {
    if (params == null)
      return params;
    else
      return params.keys
          .where((key) => key != '__requestctx' && key != '__responsectx')
          .fold({}, (map, key) => map..[key] = params[key]);
  }

  /// Closes any open [StreamController]s on this instance. **Internal use only**.
  @override
  Future close() async {
    _ctrl.forEach((c) => c.close());
    beforeIndexed._close();
    beforeRead._close();
    beforeCreated._close();
    beforeModified._close();
    beforeUpdated._close();
    beforeRemoved._close();
    afterIndexed._close();
    afterRead._close();
    afterCreated._close();
    afterModified._close();
    afterUpdated._close();
    afterRemoved._close();
    await inner.close();
  }

  /// Adds hooks to this instance.
  void addHooks() {
    Hooks hooks = getAnnotation(inner, Hooks);
    final before = [];
    final after = [];

    if (hooks != null) {
      before.addAll(hooks.before);
      after.addAll(hooks.after);
    }

    void applyListeners(Function fn, HookedServiceEventDispatcher dispatcher,
        [bool isAfter]) {
      Hooks hooks = getAnnotation(fn, Hooks);
      final listeners = []..addAll(isAfter == true ? after : before);

      if (hooks != null)
        listeners.addAll(isAfter == true ? hooks.after : hooks.before);

      listeners.forEach(dispatcher.listen);
    }

    applyListeners(inner.index, beforeIndexed);
    applyListeners(inner.read, beforeRead);
    applyListeners(inner.create, beforeCreated);
    applyListeners(inner.modify, beforeModified);
    applyListeners(inner.update, beforeUpdated);
    applyListeners(inner.remove, beforeRemoved);
    applyListeners(inner.index, afterIndexed, true);
    applyListeners(inner.read, afterRead, true);
    applyListeners(inner.create, afterCreated, true);
    applyListeners(inner.modify, afterModified, true);
    applyListeners(inner.update, afterUpdated, true);
    applyListeners(inner.remove, afterRemoved, true);
  }

  /// Adds routes to this instance.
  @override
  void addRoutes() {
    // Set up our routes. We still need to copy middleware from inner service
    Map restProvider = {'provider': Providers.rest};

    // Add global middleware if declared on the instance itself
    Middleware before = getAnnotation(inner, Middleware);
    List handlers = [
      (RequestContext req, ResponseContext res) async {
        req.serviceParams
          ..['__requestctx'] = req
          ..['__responsectx'] = res;
        return true;
      }
    ];

    if (before != null) handlers.addAll(before.handlers);

    Middleware indexMiddleware = getAnnotation(inner.index, Middleware);
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

    Middleware createMiddleware = getAnnotation(inner.create, Middleware);

    post('/', (req, res) async {
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

    Middleware readMiddleware = getAnnotation(inner.read, Middleware);

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

    Middleware modifyMiddleware = getAnnotation(inner.modify, Middleware);
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

    Middleware updateMiddleware = getAnnotation(inner.update, Middleware);
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

    Middleware removeMiddleware = getAnnotation(inner.remove, Middleware);
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

    addHooks();
  }

  /// Runs the [listener] before every service method specified.
  void before(
      Iterable<String> eventNames, HookedServiceEventListener listener) {
    eventNames.map((name) {
      switch (name) {
        case HookedServiceEvent.indexed:
          return beforeIndexed;
        case HookedServiceEvent.read:
          return beforeRead;
        case HookedServiceEvent.created:
          return beforeCreated;
        case HookedServiceEvent.modified:
          return beforeModified;
        case HookedServiceEvent.updated:
          return beforeUpdated;
        case HookedServiceEvent.removed:
          return beforeRemoved;
        default:
          throw new ArgumentError('Invalid service method: ${name}');
      }
    }).forEach((HookedServiceEventDispatcher dispatcher) =>
        dispatcher.listen(listener));
  }

  /// Runs the [listener] after every service method specified.
  void after(Iterable<String> eventNames, HookedServiceEventListener listener) {
    eventNames.map((name) {
      switch (name) {
        case HookedServiceEvent.indexed:
          return afterIndexed;
        case HookedServiceEvent.read:
          return afterRead;
        case HookedServiceEvent.created:
          return afterCreated;
        case HookedServiceEvent.modified:
          return afterModified;
        case HookedServiceEvent.updated:
          return afterUpdated;
        case HookedServiceEvent.removed:
          return afterRemoved;
        default:
          throw new ArgumentError('Invalid service method: ${name}');
      }
    }).forEach((HookedServiceEventDispatcher dispatcher) =>
        dispatcher.listen(listener));
  }

  /// Runs the [listener] before every service method.
  void beforeAll(HookedServiceEventListener listener) {
    beforeIndexed.listen(listener);
    beforeRead.listen(listener);
    beforeCreated.listen(listener);
    beforeModified.listen(listener);
    beforeUpdated.listen(listener);
    beforeRemoved.listen(listener);
  }

  /// Runs the [listener] after every service method.
  void afterAll(HookedServiceEventListener listener) {
    afterIndexed.listen(listener);
    afterRead.listen(listener);
    afterCreated.listen(listener);
    afterModified.listen(listener);
    afterUpdated.listen(listener);
    afterRemoved.listen(listener);
  }

  /// Returns a [Stream] of all events fired before every service method.
  ///
  /// *NOTE*: Only use this if you do not plan to modify events. There is no guarantee
  /// that events coming out of this [Stream] will see changes you make within the [Stream]
  /// callback.
  Stream<HookedServiceEvent> beforeAllStream() {
    var ctrl = new StreamController<HookedServiceEvent>();
    _ctrl.add(ctrl);
    before(HookedServiceEvent.all, ctrl.add);
    return ctrl.stream;
  }

  /// Returns a [Stream] of all events fired after every service method.
  ///
  /// *NOTE*: Only use this if you do not plan to modify events. There is no guarantee
  /// that events coming out of this [Stream] will see changes you make within the [Stream]
  /// callback.
  Stream<HookedServiceEvent> afterAllStream() {
    var ctrl = new StreamController<HookedServiceEvent>();
    _ctrl.add(ctrl);
    before(HookedServiceEvent.all, ctrl.add);
    return ctrl.stream;
  }

  /// Returns a [Stream] of all events fired before every service method specified.
  ///
  /// *NOTE*: Only use this if you do not plan to modify events. There is no guarantee
  /// that events coming out of this [Stream] will see changes you make within the [Stream]
  /// callback.
  Stream<HookedServiceEvent> beforeStream(Iterable<String> eventNames) {
    var ctrl = new StreamController<HookedServiceEvent>();
    _ctrl.add(ctrl);
    before(eventNames, ctrl.add);
    return ctrl.stream;
  }

  /// Returns a [Stream] of all events fired AFTER every service method specified.
  ///
  /// *NOTE*: Only use this if you do not plan to modify events. There is no guarantee
  /// that events coming out of this [Stream] will see changes you make within the [Stream]
  /// callback.
  Stream<HookedServiceEvent> afterStream(Iterable<String> eventNames) {
    var ctrl = new StreamController<HookedServiceEvent>();
    _ctrl.add(ctrl);
    after(eventNames, ctrl.add);
    return ctrl.stream;
  }

  /// Runs the [listener] before [create], [modify] and [update].
  void beforeModify(HookedServiceEventListener listener) {
    beforeCreated.listen(listener);
    beforeModified.listen(listener);
    beforeUpdated.listen(listener);
  }

  @override
  Future index([Map _params]) async {
    var params = _stripReq(_params);
    HookedServiceEvent before = await beforeIndexed._emit(
        new HookedServiceEvent(false, _getRequest(_params),
            _getResponse(_params), inner, HookedServiceEvent.indexed,
            params: params));
    if (before._canceled) {
      HookedServiceEvent after = await beforeIndexed._emit(
          new HookedServiceEvent(true, _getRequest(_params),
              _getResponse(_params), inner, HookedServiceEvent.indexed,
              params: params, result: before.result));
      return after.result;
    }

    var result = await inner.index(params);
    HookedServiceEvent after = await afterIndexed._emit(new HookedServiceEvent(
        true,
        _getRequest(_params),
        _getResponse(_params),
        inner,
        HookedServiceEvent.indexed,
        params: params,
        result: result));
    return after.result;
  }

  @override
  Future read(id, [Map _params]) async {
    var params = _stripReq(_params);
    HookedServiceEvent before = await beforeRead._emit(new HookedServiceEvent(
        false,
        _getRequest(_params),
        _getResponse(_params),
        inner,
        HookedServiceEvent.indexed,
        id: id,
        params: params));

    if (before._canceled) {
      HookedServiceEvent after = await afterRead._emit(new HookedServiceEvent(
          true,
          _getRequest(_params),
          _getResponse(_params),
          inner,
          HookedServiceEvent.read,
          id: id,
          params: params,
          result: before.result));
      return after.result;
    }

    var result = await inner.read(id, params);
    HookedServiceEvent after = await afterRead._emit(new HookedServiceEvent(
        true,
        _getRequest(_params),
        _getResponse(_params),
        inner,
        HookedServiceEvent.read,
        id: id,
        params: params,
        result: result));
    return after.result;
  }

  @override
  Future create(data, [Map _params]) async {
    var params = _stripReq(_params);
    HookedServiceEvent before = await beforeCreated._emit(
        new HookedServiceEvent(false, _getRequest(_params),
            _getResponse(_params), inner, HookedServiceEvent.created,
            data: data, params: params));

    if (before._canceled) {
      HookedServiceEvent after = await afterCreated._emit(
          new HookedServiceEvent(true, _getRequest(_params),
              _getResponse(_params), inner, HookedServiceEvent.created,
              data: data, params: params, result: before.result));
      return after.result;
    }

    var result = await inner.create(data, params);
    HookedServiceEvent after = await afterCreated._emit(new HookedServiceEvent(
        true,
        _getRequest(_params),
        _getResponse(_params),
        inner,
        HookedServiceEvent.created,
        data: data,
        params: params,
        result: result));
    return after.result;
  }

  @override
  Future modify(id, data, [Map _params]) async {
    var params = _stripReq(_params);
    HookedServiceEvent before = await beforeModified._emit(
        new HookedServiceEvent(false, _getRequest(_params),
            _getResponse(_params), inner, HookedServiceEvent.modified,
            id: id, data: data, params: params));

    if (before._canceled) {
      HookedServiceEvent after = await afterModified._emit(
          new HookedServiceEvent(true, _getRequest(_params),
              _getResponse(_params), inner, HookedServiceEvent.modified,
              id: id, data: data, params: params, result: before.result));
      return after.result;
    }

    var result = await inner.modify(id, data, params);
    HookedServiceEvent after = await afterModified._emit(new HookedServiceEvent(
        true,
        _getRequest(_params),
        _getResponse(_params),
        inner,
        HookedServiceEvent.modified,
        id: id,
        data: data,
        params: params,
        result: result));
    return after.result;
  }

  @override
  Future update(id, data, [Map _params]) async {
    var params = _stripReq(_params);
    HookedServiceEvent before = await beforeUpdated._emit(
        new HookedServiceEvent(false, _getRequest(_params),
            _getResponse(_params), inner, HookedServiceEvent.updated,
            id: id, data: data, params: params));

    if (before._canceled) {
      HookedServiceEvent after = await afterUpdated._emit(
          new HookedServiceEvent(true, _getRequest(_params),
              _getResponse(_params), inner, HookedServiceEvent.updated,
              id: id, data: data, params: params, result: before.result));
      return after.result;
    }

    var result = await inner.update(id, data, params);
    HookedServiceEvent after = await afterUpdated._emit(new HookedServiceEvent(
        true,
        _getRequest(_params),
        _getResponse(_params),
        inner,
        HookedServiceEvent.updated,
        id: id,
        data: data,
        params: params,
        result: result));
    return after.result;
  }

  @override
  Future remove(id, [Map _params]) async {
    var params = _stripReq(_params);
    HookedServiceEvent before = await beforeRemoved._emit(
        new HookedServiceEvent(false, _getRequest(_params),
            _getResponse(_params), inner, HookedServiceEvent.removed,
            id: id, params: params));

    if (before._canceled) {
      HookedServiceEvent after = await afterRemoved._emit(
          new HookedServiceEvent(true, _getRequest(_params),
              _getResponse(_params), inner, HookedServiceEvent.removed,
              id: id, params: params, result: before.result));
      return after.result;
    }

    var result = await inner.remove(id, params);
    HookedServiceEvent after = await afterRemoved._emit(new HookedServiceEvent(
        true,
        _getRequest(_params),
        _getResponse(_params),
        inner,
        HookedServiceEvent.removed,
        id: id,
        params: params,
        result: result));
    return after.result;
  }

  /// Fires an `after` event. This will not be propagated to clients,
  /// but will be broadcasted to WebSockets, etc.
  Future<HookedServiceEvent> fire(String eventName, result,
      [HookedServiceEventListener callback]) async {
    HookedServiceEventDispatcher dispatcher;

    switch (eventName) {
      case HookedServiceEvent.indexed:
        dispatcher = afterIndexed;
        break;
      case HookedServiceEvent.read:
        dispatcher = afterRead;
        break;
      case HookedServiceEvent.created:
        dispatcher = afterCreated;
        break;
      case HookedServiceEvent.modified:
        dispatcher = afterModified;
        break;
      case HookedServiceEvent.updated:
        dispatcher = afterUpdated;
        break;
      case HookedServiceEvent.removed:
        dispatcher = afterRemoved;
        break;
      default:
        throw new ArgumentError("Invalid service event name: '$eventName'");
    }

    var ev = new HookedServiceEvent(true, null, null, this, eventName);
    return await fireEvent(dispatcher, ev, callback);
  }

  /// Sends an arbitrary event down the hook chain.
  Future<HookedServiceEvent> fireEvent(
      HookedServiceEventDispatcher dispatcher, HookedServiceEvent event,
      [HookedServiceEventListener callback]) async {
    if (callback != null && event?._canceled != true) await callback(event);
    return await dispatcher._emit(event);
  }
}

/// Fired when a hooked service is invoked.
class HookedServiceEvent {
  static const String indexed = 'indexed';
  static const String read = 'read';
  static const String created = 'created';
  static const String modified = 'modified';
  static const String updated = 'updated';
  static const String removed = 'removed';

  static const List<String> all = const [
    indexed, read, created, modified, updated, removed
  ];

  /// Use this to end processing of an event.
  void cancel([result]) {
    _canceled = true;
    this.result = result ?? this.result;
  }

  /// Resolves a service from the application.
  ///
  /// Shorthand for `e.service.app.service(...)`.
  Service getService(Pattern path) => service.app.service(path);

  bool _canceled = false;
  String _eventName;
  var _id;
  bool _isAfter;
  var data;
  Map _params;
  RequestContext _request;
  ResponseContext _response;
  var result;

  String get eventName => _eventName;

  get id => _id;

  bool get isAfter => _isAfter == true;

  bool get isBefore => !isAfter;

  Map get params => _params;

  RequestContext get request => _request;

  ResponseContext get response => _response;

  /// The inner service whose method was hooked.
  Service service;

  HookedServiceEvent(this._isAfter, this._request, this._response,
      Service this.service, String this._eventName,
      {id, this.data, Map params, this.result}) {
    _id = id;
    _params = params ?? {};
  }
}

/// Triggered on a hooked service event.
typedef HookedServiceEventListener(HookedServiceEvent event);

/// Can be listened to, but events may be canceled.
class HookedServiceEventDispatcher {
  final List<StreamController<HookedServiceEvent>> _ctrl = [];
  final List<HookedServiceEventListener> listeners = [];

  void _close() {
    _ctrl.forEach((c) => c.close());
  }

  /// Fires an event, and returns it once it is either canceled, or all listeners have run.
  Future<HookedServiceEvent> _emit(HookedServiceEvent event) async {
    if (event?._canceled != true) {
      for (var listener in listeners) {
        await listener(event);

        if (event._canceled) return event;
      }
    }

    return event;
  }

  /// Returns a [Stream] containing all events fired by this dispatcher.
  ///
  /// *NOTE*: Callbacks on the returned [Stream] cannot be guaranteed to run before other [listeners].
  /// Use this only if you need a read-only stream of events.
  Stream<HookedServiceEvent> asStream() {
    var ctrl = new StreamController<HookedServiceEvent>();
    _ctrl.add(ctrl);
    listen(ctrl.add);
    return ctrl.stream;
  }

  /// Registers the listener to be called whenever an event is triggered.
  void listen(HookedServiceEventListener listener) {
    listeners.add(listener);
  }
}
