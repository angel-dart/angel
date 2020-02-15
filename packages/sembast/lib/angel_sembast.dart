import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:sembast/sembast.dart';

class SembastService extends Service<String, Map<String, dynamic>> {
  final Database database;
  final StoreRef<int, Map<String, dynamic>> store;

  /// If set to `true`, clients can remove all items by passing a `null` `id` to `remove`.
  ///
  /// `false` by default.
  final bool allowRemoveAll;

  /// If set to `true`, parameters in `req.query` are applied to the database query.
  final bool allowQuery;

  SembastService(this.database,
      {String store, this.allowRemoveAll = false, this.allowQuery = true})
      : this.store = intMapStoreFactory.store(store),
        super();

  Finder _makeQuery([Map<String, dynamic> params]) {
    params = Map<String, dynamic>.from(params ?? {});
    Filter out;
    var sort = <SortOrder>[];

    // You can pass a Finder as 'query':
    if (params['query'] is Finder) {
      return params['query'] as Finder;
    }

    for (var key in params.keys) {
      if (key == r'$sort' &&
          (allowQuery == true || !params.containsKey('provider'))) {
        var v = params[key];

        if (v is! Map) {
          sort.add(SortOrder(v.toString(), true));
        } else {
          var m = v as Map;
          m.forEach((k, sorter) {
            if (sorter is SortOrder) {
              sort.add(sorter);
            } else if (sorter is String) {
              sort.add(SortOrder(k.toString(), sorter == "-1"));
            } else if (sorter is num) {
              sort.add(SortOrder(k.toString(), sorter == -1));
            }
          });
        }
      } else if (key == 'query' &&
          (allowQuery == true || !params.containsKey('provider'))) {
        var queryObj = params[key];

        if (queryObj is Map) {
          queryObj.forEach((k, v) {
            if (k != 'provider' &&
                !const ['__requestctx', '__responsectx'].contains(k)) {
              var filter = Filter.equals(k.toString(), v);
              if (out == null) {
                out = filter;
              } else {
                out = Filter.or([out, filter]);
              }
            }
          });
        }
      }
    }

    return Finder(filter: out, sortOrders: sort);
  }

  Map<String, dynamic> _withId(Map<String, dynamic> data, String id) =>
      Map<String, dynamic>.from(data ?? {})..['id'] = id;

  @override
  Future<Map<String, dynamic>> findOne(
      [Map<String, dynamic> params,
      String errorMessage =
          'No record was found matching the given query.']) async {
    return (await store.findFirst(database, finder: _makeQuery(params)))?.value;
  }

  @override
  Future<List<Map<String, dynamic>>> index(
      [Map<String, dynamic> params]) async {
    var records = await store.find(database, finder: _makeQuery(params));
    return records
        .where((r) => r.value != null)
        .map((r) => _withId(r.value, r.key.toString()))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> read(String id,
      [Map<String, dynamic> params]) async {
    var record = await store.record(int.parse(id)).getSnapshot(database);

    if (record == null) {
      throw AngelHttpException.notFound(message: 'No record found for ID $id');
    }

    return _withId(record.value, id);
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> data,
      [Map<String, dynamic> params]) async {
    return await database.transaction((txn) async {
      var key = await store.add(txn, data);
      var id = key.toString();
      return _withId(data, id);
    });
  }

  @override
  Future<Map<String, dynamic>> modify(String id, Map<String, dynamic> data,
      [Map<String, dynamic> params]) async {
    return await database.transaction((txn) async {
      var record = store.record(int.parse(id));
      data = await record.put(txn, data, merge: true);
      return _withId(data, id);
    });
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data,
      [Map<String, dynamic> params]) async {
    return await database.transaction((txn) async {
      var record = store.record(int.parse(id));
      data = await record.put(txn, data);
      return _withId(data, id);
    });
  }

  @override
  Future<Map<String, dynamic>> remove(String id,
      [Map<String, dynamic> params]) async {
    if (id == null || id == 'null') {
      // Remove everything...
      if (!(allowRemoveAll == true ||
          params?.containsKey('provider') != true)) {
        throw AngelHttpException.forbidden(
            message: 'Clients are not allowed to delete all items.');
      } else {
        await store.delete(database);
        return {};
      }
    }

    return database.transaction((txn) async {
      var record = store.record(int.parse(id));
      var snapshot = await record.getSnapshot(txn);

      if (snapshot == null) {
        throw AngelHttpException.notFound(
            message: 'No record found for ID $id');
      } else {
        await record.delete(txn);
      }

      return _withId(snapshot.value, id);
    });
  }
}
