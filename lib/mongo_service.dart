part of angel_mongo;

/// Manipulates data from MongoDB as Maps.
class MongoService extends Service {
  DbCollection collection;

  MongoService(DbCollection this.collection) : super();

  _jsonify(Map doc, [Map params]) {
    Map result = {};
    for (var key in doc.keys) {
      if (doc[key] is ObjectId) {
        result[key] = doc[key].toHexString();
      } else
        result[key] = doc[key];
    }

    return _transformId(result);
  }

  SelectorBuilder _makeQuery([Map params_]) {
    Map params = params_ ?? {};
    params = params..remove('provider');
    SelectorBuilder result = where.exists('_id');

    for (var key in params.keys) {
      if (key == r'$sort') {
        if (params[key] is Map) {
          // If they send a map, then we'll sort by every key in the map
          for (String fieldName in params[key].keys.where((x) => x is String)) {
            var sorter = params[key][fieldName];
            if (sorter is num) {
              result = result.sortBy(fieldName, descending: sorter == -1);
            } else if (sorter is String) {
              result = result.sortBy(fieldName, descending: sorter == "-1");
            }
          }
        } else if (params[key] is String) {
          // If they send just a string, then we'll sort
          // by that, ascending
          result = result.sortBy(params[key]);
        }
      } else if (key is String) {
        result = result.and(where.eq(key, params[key]));
      }
    }

    return result;
  }

  @override
  Future<List> index([Map params]) async {
    return await (await collection.find(_makeQuery(params)))
        .map((x) => _jsonify(x, params))
        .toList();
  }

  @override
  Future create(Map data, [Map params]) async {
    Map item = (data is Map) ? data : god.serializeObject(data);
    item = _removeSensitive(item);

    try {
      item['createdAt'] = new DateTime.now();
      await collection.insert(item);
      return await _lastItem(collection, _jsonify, params);
    } catch (e, st) {
      throw new AngelHttpException(e, stackTrace: st);
    }
  }

  @override
  Future read(id, [Map params]) async {
    ObjectId _id = _makeId(id);
    Map found = await collection.findOne(where.id(_id).and(_makeQuery(params)));

    if (found == null) {
      throw new AngelHttpException.NotFound(
          message: 'No record found for ID ${_id.toHexString()}');
    }

    return _jsonify(found, params);
  }

  @override
  Future modify(id, Map data, [Map params]) async {
    Map target = await read(id, params);
    Map result = mergeMap([target, _removeSensitive(data)]);
    result['updatedAt'] = new DateTime.now();

    try {
      await collection.update(where.id(_makeId(id)), result);
      result = _jsonify(result, params);
      result['id'] = id;
      return result;
    } catch (e, st) {
      throw new AngelHttpException(e, stackTrace: st);
    }
  }

  @override
  Future update(id, data, [Map params]) async {
    Map target = await read(id, params);
    Map result = _removeSensitive(data);
    result['_id'] = _makeId(id);
    result['createdAt'] = target['createdAt'];
    result['updatedAt'] = new DateTime.now();

    try {
      await collection.update(where.id(_makeId(id)), result);
      result = _jsonify(result, params);
      result['id'] = id;
      return result;
    } catch (e, st) {
      throw new AngelHttpException(e, stackTrace: st);
    }
  }

  @override
  Future remove(id, [Map params]) async {
    Map result = await read(id, params);

    try {
      await collection.remove(where.id(_makeId(id)).and(_makeQuery(params)));
      return result;
    } catch (e, st) {
      throw new AngelHttpException(e, stackTrace: st);
    }
  }
}
