part of angel_mongo.services;

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
