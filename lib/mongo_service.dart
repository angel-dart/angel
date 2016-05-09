part of angel_mongo;

class MongoService extends Service {
  DbCollection collection;

  MongoService(DbCollection this.collection);

  Map _jsonify(Map doc) {
    Map result = {};
    for (var key in doc.keys) {
      if (doc[key] is ObjectId) {
        result[key] = doc[key].toHexString();
      } else result[key] = doc[key];
    }
    return result;
  }

  _lastItem() async {
    return (await (await collection.find(
        where.sortBy('\$natural', descending: true))).toList())
        .map(_jsonify)
        .first;
  }

  SelectorBuilder _makeQuery([Map params_]) {
    Map params = params_ ?? {};
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
      }

      else if (key is String) {
        result = result.and(where.eq(key, params[key]));
      }
    }

    return result;
  }

  @override
  Future<List> index([Map params]) async {
    return await (await collection.find(_makeQuery(params)))
        .map(_jsonify)
        .toList();
  }

  @override
  Future create(data, [Map params]) async {
    Map item = (data is Map) ? data : _god.serializeToMap(data);
    item = mergeMap([item, params]);
    item['createdAt'] = new DateTime.now();
    await collection.insert(item);
    return await _lastItem();
  }

  @override
  Future read(id, [Map params]) async {
    ObjectId id_;
    try {
      id_ = (id is ObjectId) ? id : new ObjectId.fromHexString(
          id.toString());
    } catch (e) {
      throw new AngelHttpException.BadRequest();
    }

    Map found = await collection.findOne(
        where.id(id_).and(_makeQuery(params)));

    if (found == null) {
      throw new AngelHttpException.NotFound(
          message: 'No record found for ID ${id_.toHexString()}');
    }

    return _jsonify(found);
  }
}
