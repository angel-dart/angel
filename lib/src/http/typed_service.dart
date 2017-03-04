import 'dart:async';
import 'dart:mirrors';
import 'package:json_god/json_god.dart' as god;
import '../../common.dart';
import 'service.dart';

class TypedService<T> extends Service {
  final Service inner;

  TypedService(this.inner) : super() {
    if (!reflectType(T).isAssignableTo(reflectType(Model)))
      throw new Exception(
          "If you specify a type for TypedService, it must extend Model.");
  }

  deserialize(x) {
    // print('DESERIALIZE: $x (${x.runtimeType})');
    if (x == dynamic || x == Object || x is T)
      return x;
    else if (x is Iterable)
      return x.map(deserialize).toList();
    else if (x is Map) {
      Map data = x.keys.fold({}, (map, key) {
        var value = x[key];

        if ((key == 'createdAt' || key == 'updatedAt') && value is String) {
          return map..[key] = DateTime.parse(value);
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

  serialize(x) {
    if (x is Model)
      return god.serializeObject(x);
    else if (x is Map)
      return x;
    else if (x is Iterable)
      return x.map(serialize).toList();
    else
      throw new ArgumentError('Cannot serialize ${x.runtimeType}');
  }

  @override
  Future index([Map params]) => inner.index(params).then(deserialize);

  @override
  Future create(data, [Map params]) =>
      inner.create(serialize(data), params).then(deserialize);

  @override
  Future read(id, [Map params]) => inner.read(id, params).then(deserialize);

  @override
  Future modify(id, data, [Map params]) =>
      inner.modify(id, serialize(data), params).then(deserialize);

  @override
  Future update(id, data, [Map params]) =>
      inner.update(id, serialize(data), params).then(deserialize);

  @override
  Future remove(id, [Map params]) => inner.remove(id, params).then(deserialize);
}
