import 'dart:async';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'service.dart';

/// A basic service that manages an in-memory list of maps.
class MapService extends Service {
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
      {this.allowRemoveAll: false,
      this.allowQuery: true,
      this.autoIdAndDateFields: true,
      this.autoSnakeCaseNames: true})
      : super();

  String get createdAtKey =>
      autoSnakeCaseNames == false ? 'createdAt' : 'created_at';

  String get updatedAtKey =>
      autoSnakeCaseNames == false ? 'updatedAt' : 'updated_at';

  bool Function(Map) _matchesId(id) {
    return (Map item) {
      if (item['id'] == null)
        return false;
      else if (autoIdAndDateFields != false)
        return item['id'] == id?.toString();
      else
        return item['id'] == id;
    };
  }

  @override
  Future<List> index([Map params]) async {
    if (allowQuery == false || params == null || params['query'] is! Map)
      return items;
    else {
      Map query = params['query'];

      return items.where((item) {
        for (var key in query.keys) {
          if (!item.containsKey(key))
            return false;
          else if (item[key] != query[key]) return false;
        }

        return true;
      }).toList();
    }
  }

  @override
  Future<Map> read(id, [Map params]) async {
    return items.firstWhere(_matchesId(id),
        orElse: () => throw new AngelHttpException.notFound(
            message: 'No record found for ID $id'));
  }

  @override
  Future<Map> create(data, [Map params]) async {
    if (data is! Map)
      throw new AngelHttpException.badRequest(
          message:
              'MapService does not support `create` with ${data.runtimeType}.');
    var now = new DateTime.now().toIso8601String();
    var result = data;

    if (autoIdAndDateFields == true) {
      result
        ..['id'] = items.length.toString()
        ..[autoSnakeCaseNames == false ? 'createdAt' : 'created_at'] = now
        ..[autoSnakeCaseNames == false ? 'updatedAt' : 'updated_at'] = now;
    }
    items.add(result);
    return result;
  }

  @override
  Future<Map> modify(id, data, [Map params]) async {
    if (data is! Map)
      throw new AngelHttpException.badRequest(
          message:
              'MapService does not support `modify` with ${data.runtimeType}.');
    if (!items.any(_matchesId(id))) return await create(data, params);

    var item = await read(id);
    var result = item..addAll(data);

    if (autoIdAndDateFields == true)
      result
        ..[autoSnakeCaseNames == false ? 'updatedAt' : 'updated_at'] =
            new DateTime.now().toIso8601String();
    return result;
  }

  @override
  Future<Map> update(id, data, [Map params]) async {
    if (data is! Map)
      throw new AngelHttpException.badRequest(
          message:
              'MapService does not support `update` with ${data.runtimeType}.');
    if (!items.any(_matchesId(id))) return await create(data, params);

    var old = await read(id);

    if (!items.remove(old))
      throw new AngelHttpException.notFound(
          message: 'No record found for ID $id');

    var result = data;
    if (autoIdAndDateFields == true) {
      result
        ..['id'] = id?.toString()
        ..[autoSnakeCaseNames == false ? 'createdAt' : 'created_at'] =
            old[autoSnakeCaseNames == false ? 'createdAt' : 'created_at']
        ..[autoSnakeCaseNames == false ? 'updatedAt' : 'updated_at'] =
            new DateTime.now().toIso8601String();
    }
    items.add(result);
    return result;
  }

  @override
  Future<Map> remove(id, [Map params]) async {
    if (id == null ||
        id == 'null' &&
            (allowRemoveAll == true ||
                params?.containsKey('provider') != true)) {
      items.clear();
      return {};
    }

    var result = await read(id, params);

    if (items.remove(result))
      return result;
    else
      throw new AngelHttpException.notFound(
          message: 'No record found for ID $id');
  }
}
