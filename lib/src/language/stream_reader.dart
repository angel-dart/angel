import 'dart:async';
import 'dart:collection';

class StreamReader<T> implements StreamConsumer<T> {
  final Queue<T> _buffer = new Queue();
  bool _closed = false;
  final Queue<Completer<T>> _nextQueue = new Queue();
  final Queue<Completer<T>> _peekQueue = new Queue();

  bool get isDone => _closed;

  Future<T> peek() {
    if (isDone) throw new StateError('Cannot read from closed stream.');
    if (_buffer.isNotEmpty) return new Future.value(_buffer.first);

    var c = new Completer<T>();
    _peekQueue.addLast(c);
    return c.future;
  }

  Future<T> next() {
    if (isDone) throw new StateError('Cannot read from closed stream.');
    if (_buffer.isNotEmpty) return new Future.value(_buffer.removeFirst());

    var c = new Completer<T>();
    _nextQueue.addLast(c);
    return c.future;
  }

  @override
  Future addStream(Stream<T> stream) {
    if (_closed) throw new StateError('StreamReader has already been used.');

    var c = new Completer();

    stream.listen((data) {
      if (_peekQueue.isNotEmpty || _nextQueue.isNotEmpty) {
        if (_peekQueue.isNotEmpty) {
          _peekQueue.removeFirst().complete(data);
        }

        if (_nextQueue.isNotEmpty) {
          _nextQueue.removeFirst().complete(data);
        }
      } else {
        _buffer.add(data);
      }
    })
      ..onDone(c.complete)
      ..onError(c.completeError);

    return c.future;
  }

  @override
  Future close() async {
    _closed = true;
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
