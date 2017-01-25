import 'dart:async';
import 'dart:collection';

class StreamReader<T> implements StreamConsumer<T> {
  final Queue<T> _buffer = new Queue();
  bool _closed = false;
  T _current;
  bool _onDataListening = false;
  final Queue<Completer<T>> _nextQueue = new Queue();
  final Queue<Completer<T>> _peekQueue = new Queue();

  StreamController<T> _onData;

  bool get isDone => _closed;
  Stream<T> get onData => _onData.stream;

  _onListen() {
    _onDataListening = true;
  }

  _onPause() {
    _onDataListening = false;
  }

  StreamReader() {
    _onData = new StreamController<T>(
        onListen: _onListen,
        onResume: _onListen,
        onPause: _onPause,
        onCancel: _onPause);
  }

  Future<T> current() {
    if (_current == null) {
      if (_nextQueue.isNotEmpty) return _nextQueue.first.future;
      return consume();
    }

    return new Future.value(_current);
  }

  Future<T> peek() {
    if (isDone) throw new StateError('Cannot read from closed stream.');
    if (_buffer.isNotEmpty) return new Future.value(_buffer.first);

    var c = new Completer<T>();
    _peekQueue.addLast(c);
    return c.future;
  }

  Future<T> consume() {
    if (isDone) throw new StateError('Cannot read from closed stream.');

    if (_buffer.isNotEmpty) {
      _current = _buffer.removeFirst();
      return close().then((_) => new Future.value(_current));
    }

    var c = new Completer<T>();
    _nextQueue.addLast(c);
    return c.future;
  }

  @override
  Future addStream(Stream<T> stream) {
    if (_closed) throw new StateError('StreamReader has already been used.');

    var c = new Completer();

    stream.listen((data) {
      if (_onDataListening) _onData.add(data);

      if (_peekQueue.isNotEmpty || _nextQueue.isNotEmpty) {
        if (_peekQueue.isNotEmpty) {
          _peekQueue.removeFirst().complete(data);
        }

        if (_nextQueue.isNotEmpty) {
          _nextQueue.removeFirst().complete(_current = data);
        }
      } else {
        _buffer.add(data);
      }
    })
      ..onDone(() => close().then(c.complete))
      ..onError(c.completeError);

    return c.future;
  }

  @override
  Future close() async {
    if (_buffer.isEmpty && _nextQueue.isEmpty && _peekQueue.isEmpty) {
      _closed = true;

      kill(Completer c) {
        c.completeError(new StateError(
            'Reached end of stream, although more input was expected.'));
      }

      _peekQueue.forEach(kill);
      _nextQueue.forEach(kill);
    }
  }
}

class _IteratorReader<T> {
  final Iterator<T> _tokens;

  T _current;

  _IteratorReader(this._tokens) {
    _tokens.moveNext();
  }

  T advance() {
    _current = _tokens.current;
    _tokens.moveNext();
    return _current;
  }

  bool get eof => _tokens.current == null;

  T peek() => _tokens.current;
}
