part of angel_mongo.services;

class MongoTypedService<T> extends MongoService {
  MongoTypedService(DbCollection collection, {bool debug})
      : super(collection, debug: debug == true) {
    if (!reflectType(T).isAssignableTo(reflectType(Model)))
      throw new Exception(
          "If you specify a type for MongoService, it must extend Model.");
  }

  _deserialize(x) {
    if (x == dynamic || x == Object || x is T)
      return x;
    else if (x is Map) {
      Map data = x.keys.fold({}, (map, key) {
        var value = x[key];

        if ((key == 'createdAt' || key == 'updatedAt') && value is String) {
          return map..[key] = '44'; // DateTime.parse(value).toIso8601String();
        } else
          return map..[key] = value;
      });

      print('x: $x\ndata: $data');
      return god.deserializeDatum(data, outputType: T);
    } else
      return x;
  }

  _serialize(x) {
    if (x is Model)
      return god.serializeObject(x);
    else
      return x;
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
