library angel_framework.http.memory_service;

import 'dart:async';
import 'dart:mirrors';
import 'package:json_god/json_god.dart' as god;
import 'package:merge_map/merge_map.dart';
import '../../common.dart';
import 'angel_http_exception.dart';
import 'service.dart';

int _getId(id) {
  try {
    return int.parse(id.toString());
  } catch (e) {
    throw new AngelHttpException.badRequest(message: 'Invalid ID.');
  }
}

/// DEPRECATED: Use MapService instead.
/// 
/// An in-memory [Service].
@deprecated
class MemoryService<T> extends Service {
  /// If set to `true`, clients can remove all items by passing a `null` `id` to `remove`.
  ///
  /// `false` by default.
  final bool allowRemoveAll;

  //// The data contained in this service.
  final Map<int, Model> items = {};

  MemoryService({this.allowRemoveAll: false}) : super() {
    if (!reflectType(T).isAssignableTo(reflectType(Model))) {
      throw new Exception(
          "MemoryServices only support classes that inherit from Model.");
    }
  }

  _makeJson(int index, Model t) {
    return t..id = index.toString();
  }

  Future<List> index([Map params]) async {
    return items.keys
        .where((index) => items[index] != null)
        .map((index) => _makeJson(index, items[index]))
        .toList();
  }

  Future read(id, [Map params]) async {
    int desiredId = _getId(id);
    if (items.containsKey(desiredId)) {
      Model found = items[desiredId];
      if (found != null) {
        return _makeJson(desiredId, found);
      } else
        throw new AngelHttpException.notFound();
    } else
      throw new AngelHttpException.notFound();
  }

  Future create(data, [Map params]) async {
    //try {
    Model created =
        (data is Model) ? data : god.deserializeDatum(data, outputType: T);

    int size = items.length;
    created.id = size.toString();
    items[size] = created;
    return created;
    /*} catch (e) {
      throw new AngelHttpException.BadRequest(message: 'Invalid data.');
    }*/
  }

  Future modify(id, data, [Map params]) async {
    int desiredId = _getId(id);
    if (items.containsKey(desiredId)) {
      try {
        Map existing = god.serializeObject(items[desiredId]);
        data = mergeMap([existing, data]);
        items[desiredId] =
            (data is Map) ? god.deserializeDatum(data, outputType: T) : data;
        return _makeJson(desiredId, items[desiredId]);
      } catch (e) {
        throw new AngelHttpException.badRequest(message: 'Invalid data.');
      }
    } else
      throw new AngelHttpException.notFound();
  }

  Future update(id, data, [Map params]) async {
    int desiredId = _getId(id);
    if (items.containsKey(desiredId)) {
      try {
        items[desiredId] =
            (data is Map) ? god.deserializeDatum(data, outputType: T) : data;
        return _makeJson(desiredId, items[desiredId]);
      } catch (e) {
        throw new AngelHttpException.badRequest(message: 'Invalid data.');
      }
    } else
      throw new AngelHttpException.notFound();
  }

  Future remove(id, [Map params]) async {
    if (id == null ||
        id == 'null' &&
            (allowRemoveAll == true ||
                params?.containsKey('provider') != true)) {
      items.clear();
      return {};
    }

    int desiredId = _getId(id);
    if (items.containsKey(desiredId)) {
      Model item = items[desiredId];
      items[desiredId] = null;
      return _makeJson(desiredId, item);
    } else
      throw new AngelHttpException.notFound();
  }
}
