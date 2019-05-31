import 'dart:async';

typedef void _InitCallback();

/// A [StreamController] boilerplate that prevents memory leaks.
abstract class SafeCtrl<T> {
  factory SafeCtrl() => _SingleSafeCtrl();

  factory SafeCtrl.broadcast() => _BroadcastSafeCtrl();

  Stream<T> get stream;

  void add(T event);

  void addError(error, [StackTrace stackTrace]);

  Future close();

  void whenInitialized(void callback());
}

class _SingleSafeCtrl<T> implements SafeCtrl<T> {
  StreamController<T> _stream;
  bool _hasListener = false, _initialized = false;
  _InitCallback _initializer;

  _SingleSafeCtrl() {
    _stream = StreamController<T>(onListen: () {
      _hasListener = true;

      if (!_initialized && _initializer != null) {
        _initializer();
        _initialized = true;
      }
    }, onPause: () {
      _hasListener = false;
    }, onResume: () {
      _hasListener = true;
    }, onCancel: () {
      _hasListener = false;
    });
  }

  @override
  Stream<T> get stream => _stream.stream;

  @override
  void add(T event) {
    if (_hasListener) _stream.add(event);
  }

  @override
  void addError(error, [StackTrace stackTrace]) {
    if (_hasListener) _stream.addError(error, stackTrace);
  }

  @override
  Future close() {
    return _stream.close();
  }

  @override
  void whenInitialized(void callback()) {
    if (!_initialized) {
      if (!_hasListener) {
        _initializer = callback;
      } else {
        _initializer();
        _initialized = true;
      }
    }
  }
}

class _BroadcastSafeCtrl<T> implements SafeCtrl<T> {
  StreamController<T> _stream;
  int _listeners = 0;
  bool _initialized = false;
  _InitCallback _initializer;

  _BroadcastSafeCtrl() {
    _stream = StreamController<T>.broadcast(onListen: () {
      _listeners++;

      if (!_initialized && _initializer != null) {
        _initializer();
        _initialized = true;
      }
    }, onCancel: () {
      _listeners--;
    });
  }

  @override
  Stream<T> get stream => _stream.stream;

  @override
  void add(T event) {
    if (_listeners > 0) _stream.add(event);
  }

  @override
  void addError(error, [StackTrace stackTrace]) {
    if (_listeners > 0) _stream.addError(error, stackTrace);
  }

  @override
  Future close() {
    return _stream.close();
  }

  @override
  void whenInitialized(void callback()) {
    if (!_initialized) {
      if (_listeners <= 0) {
        _initializer = callback;
      } else {
        _initializer();
        _initialized = true;
      }
    }
  }
}
