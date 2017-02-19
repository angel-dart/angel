part of angel_mongo.services;

/// Manipulates data from MongoDB as Maps.
class MongoService extends Service {
  DbCollection collection;
  final bool debug;

  MongoService(DbCollection this.collection, {this.debug: true}) : super();

  _jsonify(Map doc, [Map params]) {
    Map result = {};

    for (var key in doc.keys) {
      var value = doc[key];
      if (value is ObjectId) {
        result[key] = value.toHexString();
      } else if (value is! RequestContext && value is! ResponseContext) {
        result[key] = value;
      }
    }

    return _transformId(result);
  }

  void printDebug(e, st, msg) {
    if (debug) {
      stderr.writeln('$msg ERROR: $e');
      stderr.writeln(st);
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
    Map item = (data is Map) ? data : god.serializeObject(data);
    item = _removeSensitive(item);

    try {
      item['createdAt'] = new DateTime.now().toIso8601String();
      await collection.insert(item);
      return await _lastItem(collection, _jsonify, params);
    } catch (e, st) {
      printDebug(e, st, 'CREATE');
      throw new AngelHttpException(e, stackTrace: st);
    }
  }

  @override
  Future read(id, [Map params]) async {
    ObjectId _id = _makeId(id);
    Map found = await collection.findOne(where.id(_id).and(_makeQuery(params)));

    if (found == null) {
      throw new AngelHttpException.notFound(
          message: 'No record found for ID ${_id.toHexString()}');
    }

    return _jsonify(found, params);
  }

  @override
  Future modify(id, data, [Map params]) async {
    var target = await read(id, params);
    Map result = mergeMap([
      target is Map ? target : god.serializeObject(target),
      _removeSensitive(data)
    ]);
    result['updatedAt'] = new DateTime.now().toIso8601String();

    try {
      await collection.update(where.id(_makeId(id)), result);
      result = _jsonify(result, params);
      result['id'] = id;
      return result;
    } catch (e, st) {
      printDebug(e, st, 'MODIFY');
      throw new AngelHttpException(e, stackTrace: st);
    }
  }

  @override
  Future update(id, data, [Map params]) async {
    var target = await read(id, params);
    Map result = _removeSensitive(data);
    result['_id'] = _makeId(id);
    result['createdAt'] =
        target is Map ? target['createdAt'] : target.createdAt;

    if (result['createdAt'] is DateTime)
      result['createdAt'] = result['createdAt'].toIso8601String();

    result['updatedAt'] = new DateTime.now().toIso8601String();

    try {
      await collection.update(where.id(_makeId(id)), result);
      result = _jsonify(result, params);
      result['id'] = id;
      return result;
    } catch (e, st) {
      printDebug(e, st, 'UPDATE');
      throw new AngelHttpException(e, stackTrace: st);
    }
  }

  @override
  Future remove(id, [Map params]) async {
    var result = await read(id, params);

    try {
      await collection.remove(where.id(_makeId(id)).and(_makeQuery(params)));
      return result;
    } catch (e, st) {
      printDebug(e, st, 'REMOVE');
      throw new AngelHttpException(e, stackTrace: st);
    }
  }
}
