part of angel_mongo.services;

class MongoTypedService<T> extends MongoService {
  MongoTypedService(DbCollection collection, {bool allowRemoveAll, bool debug})
      : super(collection,
            allowRemoveAll: allowRemoveAll == true, debug: debug == true) {
    if (!reflectType(T).isAssignableTo(reflectType(Model)))
      throw new Exception(
          "If you specify a type for MongoService, it must extend Model.");
  }

  _deserialize(x) {
    // print('DESERIALIZE: $x (${x.runtimeType})');
    if (x == dynamic || x == Object || x is T)
      return x;
    else if (x is Map) {
      Map data = x.keys.fold({}, (map, key) {
        var value = x[key];

        if ((key == 'createdAt' || key == 'updatedAt') && value is String) {
          return map..[key] = DateTime.parse(value).toIso8601String();
        } else if (value is DateTime) {
          return map..[key] = value.toIso8601String();
        } else {
          return map..[key] = value;
        }
      });

      Model result = god.deserializeDatum(data, outputType: T);

      if (x['createdAt'] is String) {
        result.createdAt = DateTime.parse(x['createdAt']);
      } else if (x['createdAt'] is DateTime) {
        result.createdAt = x['createdAt'];
      }

      if (x['updatedAt'] is String) {
        result.updatedAt = DateTime.parse(x['updatedAt']);
      } else if (x['updatedAt'] is DateTime) {
        result.updatedAt = x['updatedAt'];
      }

      // print('x: $x\nresult: $result');
      return result;
    } else
      return x;
  }

  _serialize(x) {
    if (x is Model)
      return god.serializeObject(x);
    else if (x is Map)
      return x;
    else
      throw new ArgumentError('Cannot serialize ${x.runtimeType}');
  }

  @override
  Future<List> index([Map params]) async {
    var result = await super.index(params);
    return result.map(_deserialize).toList();
  }

  @override
  Future create(data, [Map params]) =>
      super.create(_serialize(data), params).then(_deserialize);

  @override
  Future read(id, [Map params]) => super.read(id, params).then(_deserialize);

  @override
  Future modify(id, data, [Map params]) =>
      super.modify(id, _serialize(data), params).then(_deserialize);

  @override
  Future update(id, data, [Map params]) =>
      super.update(id, _serialize(data), params).then(_deserialize);

  @override
  Future remove(id, [Map params]) =>
      super.remove(id, params).then(_deserialize);
}
