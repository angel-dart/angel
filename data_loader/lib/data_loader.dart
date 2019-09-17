import 'dart:async';
import 'dart:collection';

/// A utility for batching multiple requests together, to improve application performance.
///
/// Enqueues batches of requests until the next tick, when they are processed in bulk.
///
/// Port of Facebook's `DataLoader`:
/// https://github.com/graphql/dataloader
class DataLoader<Id, Data> {
  /// Invoked to fetch a batch of keys simultaneously.
  final FutureOr<Iterable<Data>> Function(Iterable<Id>) loadMany;

  /// Whether to use a memoization cache to store the results of past lookups.
  final bool cache;

  var _cache = <Id, Data>{};
  var _queue = Queue<_QueueItem<Id, Data>>();
  bool _started = false;

  DataLoader(this.loadMany, {this.cache = true});

  Future<void> _onTick() async {
    if (_queue.isNotEmpty) {
      var current = _queue.toList();
      _queue.clear();

      List<Id> loadIds =
          current.map((i) => i.id).toSet().toList(growable: false);

      var data = await loadMany(
        loadIds,
      );

      for (int i = 0; i < loadIds.length; i++) {
        var id = loadIds[i];
        var value = data.elementAt(i);

        if (cache) _cache[id] = value;

        current
            .where((item) => item.id == id)
            .forEach((item) => item.completer.complete(value));
      }
    }

    _started = false;
    // if (!_closed) scheduleMicrotask(_onTick);
  }

  /// Clears the value at [key], if it exists.
  void clear(Id key) => _cache.remove(key);

  /// Clears the entire cache.
  void clearAll() => _cache.clear();

  /// Primes the cache with the provided key and value. If the key already exists, no change is made.
  ///
  /// To forcefully prime the cache, clear the key first with
  /// `loader..clear(key)..prime(key, value)`.
  void prime(Id key, Data value) => _cache.putIfAbsent(key, () => value);

  /// Closes this [DataLoader], cancelling all pending requests.
  void close() {
    while (_queue.isNotEmpty) {
      _queue.removeFirst().completer.completeError(
          StateError('The DataLoader was closed before the item was loaded.'));
    }

    _queue.clear();
  }

  /// Returns a [Future] that completes when the next batch of requests completes.
  Future<Data> load(Id id) {
    if (cache && _cache.containsKey(id)) {
      return Future<Data>.value(_cache[id]);
    } else {
      var item = _QueueItem<Id, Data>(id);
      _queue.add(item);
      if (!_started) {
        _started = true;
        scheduleMicrotask(_onTick);
      }
      return item.completer.future;
    }
  }
}

class _QueueItem<Id, Data> {
  final Id id;
  final Completer<Data> completer = Completer();

  _QueueItem(this.id);
}
