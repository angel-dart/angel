library angel_mongo;

import 'dart:async';
import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:merge_map/merge_map.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'mongo_service.dart';

part 'mongo_service_typed.dart';

/// A data type that can be serialized to MongoDB.
class Model {
  /// This instance's ID.
  String id;

  /// The time at which this instance was created.
  DateTime createdAt;

  /// The time at which this instance was last updated.
  DateTime updatedAt;
}


Map _transformId(Map doc) {
  Map result = mergeMap([doc]);
  result['id'] = doc['_id'];

  return result..remove('_id');
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
    throw new AngelHttpException.BadRequest();
  }
}

Map _removeSensitive(Map data) {
  return data..remove('id')..remove('_id')..remove('createdAt')..remove(
      'updatedAt');
}

SelectorBuilder _makeQuery([Map params_]) {
  Map params = params_ ?? {};
  params = params..remove('provider');
  SelectorBuilder result = where.exists('_id');

  // You can pass a SelectorBuilder as 'query';
  if (params['query'] != null && params['query'] is SelectorBuilder)
    return params['query'];

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
