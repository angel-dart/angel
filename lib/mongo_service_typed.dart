part of angel_mongo;

/// Manipulates data from MongoDB by serializing BSON from and deserializing BSON to a target class.
class MongoTypedService<T> extends Service {
  DbCollection collection;

  MongoTypedService(DbCollection this.collection):super() {
    if (!reflectType(T).isAssignableTo(reflectType(Model)))
      throw new Exception(
          "If you specify a type for MongoService, it must be dynamic, Map, or extend from Model.");
  }

  Map _transformId(Map doc) {
    Map result = mergeMap([doc]);
    result['id'] = doc['_id'];

    return result..remove('_id');
  }

  _jsonify(Map doc, [Map params]) {
    Map result = {};
    for (var key in doc.keys) {
      if (doc[key] is ObjectId) {
        result[key] = doc[key].toHexString();
      } else
        result[key] = doc[key];
    }

    result = _transformId(result);

    // Clients will always receive JSON.
    if ((params != null && params['provider'] != null)) {
      return result;
    }
    else {
      // However, when we run server-side, we should return a T, not a Map.
      Model typedResult = god.deserializeDatum(result, outputType: T);
      typedResult.createdAt = result['createdAt'];
      typedResult.updatedAt = result['updatedAt'];
      return typedResult;
    }
  }

  @override
  Future<List> index([Map params]) async {
    return await (await collection.find(_makeQuery(params)))
        .map((x) => _jsonify(x, params))
        .toList();
  }

  @override
  Future create(data, [Map params]) async {
    Map item;

    try {
      Model target =
      (data is T) ? data : god.deserializeDatum(data, outputType: T);
      item = god.serializeObject(target);
      item = _removeSensitive(item);

      item['createdAt'] = new DateTime.now();
      await collection.insert(item);
      return await _lastItem(collection, _jsonify, params);
    } catch (e, st) {
      print(e);
      print(st);
      throw new AngelHttpException.BadRequest();
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
    ObjectId _id = _makeId(id);
    try {
      Map result = await collection.findOne(
          where.id(_id).and(_makeQuery(params)));

      if (result == null) {
        throw new AngelHttpException.NotFound(
            message: 'No record found for ID ${_id.toHexString()}');
      }

      result = mergeMap([result, _removeSensitive(data)]);
      result['_id'] = _id;
      result['updatedAt'] = new DateTime.now();

      await collection.update(where.id(_id), result);
      return await read(_id, params);
    } catch (e, st) {
      throw new AngelHttpException(e, stackTrace: st);
    }
  }

  @override
  Future update(id, _data, [Map params]) async {
    try {
      Model data = (_data is T) ? _data : god.deserializeDatum(
          _data, outputType: T);
      ObjectId _id = _makeId(id);
      Map rawData = _removeSensitive(god.serializeObject(data));
      rawData['_id'] = _id;
      rawData['createdAt'] = data.createdAt;
      rawData['updatedAt'] = new DateTime.now();

      await collection.update(where.id(_id).and(_makeQuery(params)), rawData);
      var result = _jsonify(rawData, params);

      if (result is T) {
        result.createdAt = data.createdAt;
        result.updatedAt = rawData['updatedAt'];
      }
      return result;
    } catch (e, st) {
      throw new AngelHttpException(e, stackTrace: st);
    }
  }
}
