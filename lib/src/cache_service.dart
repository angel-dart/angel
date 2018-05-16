import 'dart:async';
import 'package:collection/collection.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:meta/meta.dart';

/// An Angel [Service] that caches data from another service.
///
/// This is useful for applications of scale, where network latency
/// can have real implications on application performance.
class CacheService extends Service {
  /// The underlying [Service] that represents the original data store.
  final Service database;

  /// The [Service] used to interface with a caching layer.
  ///
  /// If not provided, this defaults to a [MapService].
  final Service cache;

  final bool ignoreQuery;

  final Duration timeout;

  final Map<dynamic, _CachedItem> _cache = {};
  _CachedItem _indexed;

  CacheService(
      {@required this.database,
      Service cache,
      this.ignoreQuery: false,
      this.timeout})
      : this.cache = cache ?? new MapService() {
    assert(database != null);
  }

  Future _getCached(Map params, _CachedItem get(), Future getFresh(),
      Future getCached(), Future save(data, DateTime now)) async {
    var cached = get();
    var now = new DateTime.now().toUtc();

    if (cached != null) {
      // If the entry has expired, don't send from the cache
      var expired =
          timeout != null && now.difference(cached.timestamp) >= timeout;

      if (timeout == null || !expired) {
        // Read from the cache if necessary
        var queryEqual = ignoreQuery == true ||
            (params != null &&
                cached.params != null &&
                const MapEquality()
                    .equals(params['query'], cached.params['query']));
        if (queryEqual) {
          return await getCached();
        }
      }
    }

    // If we haven't fetched from the cache by this point,
    // let's fetch from the database.
    var data = await getFresh();
    await save(data, now);
    return data;
  }

  @override
  Future index([Map params]) {
    return _getCached(
      params,
      () => _indexed,
      () => database.index(params),
      () => _indexed.data,
      (data, now) async {
        _indexed = new _CachedItem(params, now, data);
        return data;
      },
    );
  }

  @override
  Future read(id, [Map params]) async {
    return _getCached(
      params,
      () => _cache[id],
      () => database.read(id, params),
      () => cache.read(id),
      (data, now) async {
        _cache[id] = new _CachedItem(params, now, data);
        return await cache.modify(id, data);
      },
    );
  }

  @override
  Future create(data, [Map params]) {
    _indexed = null;
    return database.create(data, params);
  }

  @override
  Future modify(id, data, [Map params]) {
    _indexed = null;
    _cache.remove(id);
    return database.modify(id, data, params);
  }

  @override
  Future update(id, data, [Map params]) {
    _indexed = null;
    _cache.remove(id);
    return database.modify(id, data, params);
  }

  @override
  Future remove(id, [Map params]) {
    _indexed = null;
    _cache.remove(id);
    return database.remove(id, params);
  }
}

class _CachedItem {
  final params;
  final DateTime timestamp;
  final data;

  _CachedItem(this.params, this.timestamp, [this.data]);

  @override
  String toString() {
    return '$timestamp:$params:$data';
  }
}
