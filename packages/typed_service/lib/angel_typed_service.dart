import 'dart:async';
import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'package:json_god/json_god.dart' as god;

/// An Angel service that uses reflection to (de)serialize Dart objects.
class TypedService<Id, T> extends Service<Id, T> {
  /// The inner service.
  final Service<Id, Map<String, dynamic>> inner;

  TypedService(this.inner) : super() {
    if (!reflectType(T).isAssignableTo(reflectType(Model)))
      throw Exception(
          "If you specify a type for TypedService, it must extend Model.");
  }

  @override
  FutureOr<T> Function(RequestContext, ResponseContext) get readData =>
      _readData;

  T _readData(RequestContext req, ResponseContext res) =>
      deserialize(req.bodyAsMap);

  /// Attempts to deserialize [x] into an instance of [T].
  T deserialize(x) {
    // print('DESERIALIZE: $x (${x.runtimeType})');
    if (x is T)
      return x;
    else if (x is Map) {
      Map data = x.keys.fold({}, (map, key) {
        var value = x[key];

        if ((key == 'createdAt' ||
                key == 'updatedAt' ||
                key == 'created_at' ||
                key == 'updated_at') &&
            value is String) {
          return map..[key] = DateTime.parse(value);
        } else {
          return map..[key] = value;
        }
      });

      var result = god.deserializeDatum(data, outputType: T);

      if (data['createdAt'] is DateTime) {
        result.createdAt = data['createdAt'] as DateTime;
      } else if (data['created_at'] is DateTime) {
        result.createdAt = data['created_at'] as DateTime;
      }

      if (data['updatedAt'] is DateTime) {
        result.updatedAt = data['updatedAt'] as DateTime;
      } else if (data['updated_at'] is DateTime) {
        result.updatedAt = data['updated_at'] as DateTime;
      }

      // print('x: $x\nresult: $result');
      return result as T;
    } else
      throw ArgumentError('Cannot convert $x to $T');
  }

  /// Serializes [x] into a [Map].
  Map<String, dynamic> serialize(x) {
    if (x is Model)
      return (god.serializeObject(x) as Map).cast<String, dynamic>();
    else if (x is Map)
      return x.cast<String, dynamic>();
    else
      throw ArgumentError('Cannot serialize ${x.runtimeType}');
  }

  @override
  Future<List<T>> index([Map<String, dynamic> params]) =>
      inner.index(params).then((it) => it.map(deserialize).toList());

  @override
  Future<T> create(data, [Map<String, dynamic> params]) =>
      inner.create(serialize(data), params).then(deserialize);

  @override
  Future<T> read(Id id, [Map<String, dynamic> params]) =>
      inner.read(id, params).then(deserialize);

  @override
  Future<T> modify(Id id, T data, [Map<String, dynamic> params]) =>
      inner.modify(id, serialize(data), params).then(deserialize);

  @override
  Future<T> update(Id id, T data, [Map<String, dynamic> params]) =>
      inner.update(id, serialize(data), params).then(deserialize);

  @override
  Future<T> remove(Id id, [Map<String, dynamic> params]) =>
      inner.remove(id, params).then(deserialize);
}
