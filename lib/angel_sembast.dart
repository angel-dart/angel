import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:sembast/sembast.dart';

class SembastService extends Service<String, Map<String, dynamic>> {
  final Database database;
  final Store store;

  /// If set to `true`, clients can remove all items by passing a `null` `id` to `remove`.
  ///
  /// `false` by default.
  final bool allowRemoveAll;

  /// If set to `true`, parameters in `req.query` are applied to the database query.
  final bool allowQuery;

  SembastService(this.database,
      {String store, this.allowRemoveAll: false, this.allowQuery: true})
      : this.store =
            (store == null ? database.mainStore : database.getStore(store)),
        super();

  Finder _makeQuery([Map<String, dynamic> params]) {
    params = new Map<String, dynamic>.from(params ?? {});
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
          sort.add(new SortOrder(v.toString(), true));
        } else {
          var m = v as Map;
          m.forEach((k, sorter) {
            if (sorter is SortOrder) {
              sort.add(sorter);
            } else if (sorter is String) {
              sort.add(new SortOrder(k.toString(), sorter == "-1"));
            } else if (sorter is num) {
              sort.add(new SortOrder(k.toString(), sorter == -1));
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
              var filter = new Filter.equal(k.toString(), v);
              if (out == null)
                out = filter;
              else
                out = new Filter.or([out, filter]);
            }
          });
        }
      }
    }

    return new Finder(filter: out, sortOrders: sort);
  }

  Map<String, dynamic> _jsonify(Record record) {
    return new Map<String, dynamic>.from(record.value as Map)
      ..['id'] = record.key.toString();
  }

  @override
  Future<Map<String, dynamic>> findOne(
      [Map<String, dynamic> params,
      String errorMessage = 'No record was found matching the given query.']) {
    return store.findRecord(_makeQuery(params)).then(_jsonify);
  }

  @override
  Future<List<Map<String, dynamic>>> index(
      [Map<String, dynamic> params]) async {
    var records = await store.findRecords(_makeQuery(params));
    return records.where((r) => r.value != null).map(_jsonify).toList();
  }

  @override
  Future<Map<String, dynamic>> read(String id,
      [Map<String, dynamic> params]) async {
    var record = await store.get(int.parse(id));

    if (record == null) {
      throw new AngelHttpException.notFound(
          message: 'No record found for ID $id');
    }

    return (record as Map<String, dynamic>)..['id'] = id;
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> data,
      [Map<String, dynamic> params]) async {
    return await database.transaction((txn) async {
      var store = txn.getStore(this.store.name);
      var key = await store.put(data) as int;
      var id = key.toString();
      data = new Map<String, dynamic>.from(data)..['id'] = id;
      return data;
    });
  }

  @override
  Future<Map<String, dynamic>> modify(String id, Map<String, dynamic> data,
      [Map<String, dynamic> params]) async {
    data = new Map<String, dynamic>.from(data)..['id'] = id;

    return await database.transaction((txn) async {
      var store = txn.getStore(this.store.name);
      var existing = await store.get(int.parse(id));

      data =
          new Map<String, dynamic>.from(existing as Map<String, dynamic> ?? {})
            ..addAll(data)
            ..['id'] = id;

      await store.put(data, int.parse(id));
      return (await store.get(int.parse(id)) as Map<String, dynamic>)
        ..['id'] = id;
    });
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data,
      [Map<String, dynamic> params]) async {
    data = new Map<String, dynamic>.from(data)..['id'] = id;

    return await database.transaction((txn) async {
      var store = txn.getStore(this.store.name);
      await store.put(data, int.parse(id));
      return (await store.get(int.parse(id)) as Map<String, dynamic>)
        ..['id'] = id;
    });
  }

  @override
  Future<Map<String, dynamic>> remove(String id,
      [Map<String, dynamic> params]) async {
    return database.transaction((txn) async {
      var store = txn.getStore(this.store.name);
      var record = await store.get(int.parse(id)) as Map<String, dynamic>;

      if (record == null) {
        throw new AngelHttpException.notFound(
            message: 'No record found for ID $id');
      } else {
        await store.delete(id);
      }

      return record..['id'] = id;
    });
  }
}
