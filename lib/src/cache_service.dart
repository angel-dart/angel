import 'dart:async';
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

  CacheService({@required this.database, Service cache})
      : this.cache = cache ?? new MapService() {
    assert(database != null);
  }

  @override
  Future create(data, [Map params]) {
    return database.create(data, params);
  }

  @override
  Future modify(id, data, [Map params]) {
    return database.modify(id, data, params);
  }

  @override
  Future update(id, data, [Map params]) {
    return database.modify(id, data, params);
  }

  @override
  Future remove(id, [Map params]) {
    return database.remove(id, params);
  }
}
