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

  final List<Map<String, dynamic>> items = [];

  MapService({this.allowRemoveAll: false, this.allowQuery: true}) : super();

  _matchesId(id) {
    return (Map item) => item['id'] != null && item['id'] == id?.toString();
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
    var now = new DateTime.now();
    var result = data
      ..['id'] = items.length.toString()
      ..['createdAt'] = now
      ..['updatedAt'] = now;
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
    return item
      ..addAll(data)
      ..['updatedAt'] = new DateTime.now();
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

    var result = data
      ..['id'] = id?.toString()
      ..['createdAt'] = old['createdAt']
      ..['updatedAt'] = new DateTime.now();
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
