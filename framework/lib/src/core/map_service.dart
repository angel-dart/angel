import 'dart:async';

import 'package:angel_http_exception/angel_http_exception.dart';

import 'service.dart';

/// A basic service that manages an in-memory list of maps.
class MapService extends Service<String, Map<String, dynamic>> {
  /// If set to `true`, clients can remove all items by passing a `null` `id` to `remove`.
  ///
  /// `false` by default.
  final bool allowRemoveAll;

  /// If set to `true`, parameters in `req.query` are applied to the database query.
  final bool allowQuery;

  /// If set to `true` (default), then the service will manage an `id` string and `createdAt` and `updatedAt` fields.
  final bool autoIdAndDateFields;

  /// If set to `true` (default), then the keys `created_at` and `updated_at` will automatically be snake_cased.
  final bool autoSnakeCaseNames;

  final List<Map<String, dynamic>> items = [];

  MapService(
      {this.allowRemoveAll = false,
      this.allowQuery = true,
      this.autoIdAndDateFields = true,
      this.autoSnakeCaseNames = true})
      : super();

  String get createdAtKey =>
      autoSnakeCaseNames == false ? 'createdAt' : 'created_at';

  String get updatedAtKey =>
      autoSnakeCaseNames == false ? 'updatedAt' : 'updated_at';

  bool Function(Map<String, dynamic>) _matchesId(id) {
    return (Map<String, dynamic> item) {
      if (item['id'] == null) {
        return false;
      } else if (autoIdAndDateFields != false) {
        return item['id'] == id?.toString();
      } else {
        return item['id'] == id;
      }
    };
  }

  @override
  Future<List<Map<String, dynamic>>> index([Map<String, dynamic> params]) {
    if (allowQuery == false || params == null || params['query'] is! Map) {
      return Future.value(items);
    } else {
      var query = params['query'] as Map;

      return Future.value(items.where((item) {
        for (var key in query.keys) {
          if (!item.containsKey(key)) {
            return false;
          } else if (item[key] != query[key]) return false;
        }

        return true;
      }).toList());
    }
  }

  @override
  Future<Map<String, dynamic>> read(String id, [Map<String, dynamic> params]) {
    return Future.value(items.firstWhere(_matchesId(id),
        orElse: () => throw AngelHttpException.notFound(
            message: 'No record found for ID $id')));
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> data,
      [Map<String, dynamic> params]) {
    if (data is! Map) {
      throw AngelHttpException.badRequest(
          message:
              'MapService does not support `create` with ${data.runtimeType}.');
    }
    var now = DateTime.now().toIso8601String();
    var result = Map<String, dynamic>.from(data);

    if (autoIdAndDateFields == true) {
      result
        ..['id'] = items.length.toString()
        ..[autoSnakeCaseNames == false ? 'createdAt' : 'created_at'] = now
        ..[autoSnakeCaseNames == false ? 'updatedAt' : 'updated_at'] = now;
    }
    items.add(result);
    return Future.value(result);
  }

  @override
  Future<Map<String, dynamic>> modify(String id, Map<String, dynamic> data,
      [Map<String, dynamic> params]) {
    if (data is! Map) {
      throw AngelHttpException.badRequest(
          message:
              'MapService does not support `modify` with ${data.runtimeType}.');
    }
    if (!items.any(_matchesId(id))) return create(data, params);

    return read(id).then((item) {
      var idx = items.indexOf(item);
      if (idx < 0) return create(data, params);
      var result = Map<String, dynamic>.from(item)..addAll(data);

      if (autoIdAndDateFields == true) {
        result
          ..[autoSnakeCaseNames == false ? 'updatedAt' : 'updated_at'] =
              DateTime.now().toIso8601String();
      }
      return Future.value(items[idx] = result);
    });
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data,
      [Map<String, dynamic> params]) {
    if (data is! Map) {
      throw AngelHttpException.badRequest(
          message:
              'MapService does not support `update` with ${data.runtimeType}.');
    }
    if (!items.any(_matchesId(id))) return create(data, params);

    return read(id).then((old) {
      if (!items.remove(old)) {
        throw AngelHttpException.notFound(
            message: 'No record found for ID $id');
      }

      var result = Map<String, dynamic>.from(data);
      if (autoIdAndDateFields == true) {
        result
          ..['id'] = id?.toString()
          ..[autoSnakeCaseNames == false ? 'createdAt' : 'created_at'] =
              old[autoSnakeCaseNames == false ? 'createdAt' : 'created_at']
          ..[autoSnakeCaseNames == false ? 'updatedAt' : 'updated_at'] =
              DateTime.now().toIso8601String();
      }
      items.add(result);
      return Future.value(result);
    });
  }

  @override
  Future<Map<String, dynamic>> remove(String id,
      [Map<String, dynamic> params]) {
    if (id == null || id == 'null') {
      // Remove everything...
      if (!(allowRemoveAll == true ||
          params?.containsKey('provider') != true)) {
        throw AngelHttpException.forbidden(
            message: 'Clients are not allowed to delete all items.');
      } else {
        items.clear();
        return Future.value({});
      }
    }

    return read(id, params).then((result) {
      if (items.remove(result)) {
        return result;
      } else {
        throw AngelHttpException.notFound(
            message: 'No record found for ID $id');
      }
    });
  }
}
