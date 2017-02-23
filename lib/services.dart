library angel_mongo.services;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/common.dart' show Model;
import 'package:json_god/json_god.dart' as god;
import 'package:merge_map/merge_map.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'mongo_service.dart';

part 'mongo_service_typed.dart';

Map _transformId(Map doc) {
  Map result = mergeMap([doc]);
  result
    ..['id'] = doc['_id']
    ..remove('_id');

  return result;
}

_lastItem(DbCollection collection, Function _jsonify, [Map params]) async {
  return (await (await collection
              .find(where.sortBy('\$natural', descending: true)))
          .toList())
      .map((x) => _jsonify(x, params))
      .first;
}

ObjectId _makeId(id) {
  try {
    return (id is ObjectId) ? id : new ObjectId.fromHexString(id.toString());
  } catch (e) {
    throw new AngelHttpException.badRequest();
  }
}

const List<String> _SENSITIVE = const ['id', '_id', 'createdAt', 'updatedAt'];

Map _removeSensitive(Map data) {
  return data.keys
      .where((k) => !_SENSITIVE.contains(k))
      .fold({}, (map, key) => map..[key] = data[key]);
}

const List<String> _NO_QUERY = const ['__requestctx', '__responsectx'];

Map _filterNoQuery(Map data) {
  return data.keys.fold({}, (map, key) {
    var value = data[key];

    if (_NO_QUERY.contains(key) ||
        value is RequestContext ||
        value is ResponseContext) return map;
    if (key is! Map) return map..[key] = value;
    return map..[key] = _filterNoQuery(value);
  });
}
