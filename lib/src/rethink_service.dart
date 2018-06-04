import 'dart:async';
//import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:rethinkdb_driver/rethinkdb_driver.dart';

// Extends a RethinkDB query.
typedef RqlQuery QueryCallback(RqlQuery query);

/// Queries a single RethinkDB table or query.
class RethinkService extends Service {
  /// If set to `true`, clients can remove all items by passing a `null` `id` to `remove`.
  ///
  /// `false` by default.
  final bool allowRemoveAll;

  /// If set to `true`, parameters in `req.query` are applied to the database query.
  final bool allowQuery;

  final bool debug;

  /// If set to `true`, then a HookedService mounted over this instance
  /// will fire events when RethinkDB pushes events.
  ///
  /// Good for scaling. ;)
  final bool listenForChanges;

  final Connection connection;

  /// Doesn't actually have to be a table, just a RethinkDB query.
  ///
  /// However, a table is the most common usecase.
  final RqlQuery table;

  RethinkService(this.connection, this.table,
      {this.allowRemoveAll: false,
      this.allowQuery: true,
      this.debug: false,
      this.listenForChanges: true})
      : super() {}

  RqlQuery buildQuery(RqlQuery initialQuery, Map params) {
    if (params != null)
      params['broadcast'] = params.containsKey('broadcast')
          ? params['broadcast']
          : (listenForChanges != true);

    var q = _getQueryInner(initialQuery, params);

    if (params?.containsKey('reql') == true && params['reql'] is QueryCallback)
      q = params['reql'](q);

    return q ?? initialQuery;
  }

  RqlQuery _getQueryInner(RqlQuery query, Map params) {
    if (params == null || !params.containsKey('query'))
      return query;
    else {
      if (params['query'] is RqlQuery)
        return params['query'];
      else if (params['query'] is QueryCallback)
        return params['query'](table);
      else if (params['query'] is! Map || allowQuery != true)
        return query;
      else {
        Map q = params['query'];
        return q.keys.fold<RqlQuery>(query, (out, key) {
          var val = q[key];

          if (val is RequestContext ||
              val is ResponseContext ||
              key == 'provider' ||
              val is Providers)
            return out;
          else {
            return out.filter({key.toString(): val});
          }
        });
      }
    }
  }

  Future _sendQuery(RqlQuery query) async {
    var result = await query.run(connection);

    if (result is Cursor)
      return await result.toList();
    else if (result is Map && result['generated_keys'] is List) {
      if (result['generated_keys'].length == 1)
        return await read(result['generated_keys'].first);
      return await Future.wait(result['generated_keys'].map(read));
    } else
      return result;
  }

  _serialize(data) {
    if (data is Map)
      return data;
    else if (data is Iterable)
      return data.map(_serialize).toList();
    else
      return god.serializeObject(data);
  }

  _squeeze(data) {
    if (data is Map)
      return data.keys.fold<Map>({}, (map, k) => map..[k.toString()] = data[k]);
    else if (data is Iterable)
      return data.map(_squeeze).toList();
    else
      return data;
  }

  void onHooked(HookedService hookedService) {
    if (listenForChanges == true) {
      listenToQuery(table, hookedService);
    }
  }

  Future listenToQuery(RqlQuery query, HookedService hookedService) async {
    Feed feed = await query.changes({'include_types': true}).run(connection);

    feed.listen((Map event) {
      String type = event['type']?.toString();
      var newVal = event['new_val'], oldVal = event['old_val'];

      if (type == 'add') {
        // Create
        hookedService.fireEvent(
            hookedService.afterCreated,
            new HookedServiceEvent(
                true, null, null, this, HookedServiceEvent.created,
                result: newVal));
      } else if (type == 'change') {
        // Update
        hookedService.fireEvent(
            hookedService.afterCreated,
            new HookedServiceEvent(
                true, null, null, this, HookedServiceEvent.updated,
                result: newVal, id: oldVal['id'], data: newVal));
      } else if (type == 'remove') {
        // Remove
        hookedService.fireEvent(
            hookedService.afterCreated,
            new HookedServiceEvent(
                true, null, null, this, HookedServiceEvent.removed,
                result: oldVal, id: oldVal['id']));
      }
    });
  }

  @override
  Future index([Map params]) async {
    var query = buildQuery(table, params);
    return await _sendQuery(query);
  }

  @override
  Future read(id, [Map params]) async {
    var query = buildQuery(table.get(id?.toString()), params);
    var found = await _sendQuery(query);
    //print('Found for $id: $found');

    if (found == null) {
      throw new AngelHttpException.notFound(
          message: 'No record found for ID $id');
    } else
      return found;
  }

  @override
  Future create(data, [Map params]) async {
    if (table is! Table) throw new AngelHttpException.methodNotAllowed();

    var d = _serialize(data);
    var q = table as Table;
    var query = buildQuery(q.insert(_squeeze(d)), params);
    return await _sendQuery(query);
  }

  @override
  Future modify(id, data, [Map params]) async {
    var d = _serialize(data);

    if (d is Map && d.containsKey('id')) {
      try {
        await read(d['id'], params);
      } on AngelHttpException catch (e) {
        if (e.statusCode == 404)
          return await create(data, params);
        else
          rethrow;
      }
    }

    var query = buildQuery(table.get(id?.toString()), params).update(d);
    await _sendQuery(query);
    return await read(id, params);
  }

  @override
  Future update(id, data, [Map params]) async {
    var d = _serialize(data);

    if (d is Map && d.containsKey('id')) {
      try {
        await read(d['id'], params);
      } on AngelHttpException catch (e) {
        if (e.statusCode == 404)
          return await create(data, params);
        else
          rethrow;
      }
    }

    if (d is Map && !d.containsKey('id')) d['id'] = id.toString();
    var query = buildQuery(table.get(id?.toString()), params).replace(d);
    await _sendQuery(query);
    return await read(id, params);
  }

  @override
  Future remove(id, [Map params]) async {
    if (id == null ||
        id == 'null' &&
            (allowRemoveAll == true ||
                params?.containsKey('provider') != true)) {
      return await _sendQuery(table.delete());
    } else {
      var prior = await read(id, params);
      var query = buildQuery(table.get(id), params).delete();
      await _sendQuery(query);
      return prior;
    }
  }
}
