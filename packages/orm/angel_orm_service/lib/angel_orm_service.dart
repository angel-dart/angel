import 'dart:async';
import 'package:angel_framework/angel_framework.dart' hide Query;
import 'package:angel_orm/angel_orm.dart';

/// A [Service] implementation that wraps over a [Query] class generated
/// via the Angel ORM.
class OrmService<Id, Data, TQuery extends Query<Data, QueryWhere>>
    extends Service<Id, Data> {
  /// The [QueryExecutor] used to communicate with a database.
  final QueryExecutor executor;

  /// A callback that produces an instance of [TQuery].
  final FutureOr<TQuery> Function() queryCreator;

  /// The name of the primary key in the database table.
  ///
  /// Defaults to `'id'`.
  final String idField;

  /// If set to `true`, clients can remove all items by passing a `null` `id` to `remove`.
  ///
  /// `false` by default.
  final bool allowRemoveAll;

  /// If set to `true`, parameters in `req.queryParameters` are applied to the database query.
  final bool allowQuery;

  /// In most cases, you will want to provide [readData].
  ///
  /// Note that you won't need to call `RequestContext.parseBody`, as by the time
  /// `readData` is invoked, the body will have already been parsed.
  OrmService(this.executor, this.queryCreator,
      {this.idField = 'id',
      this.allowRemoveAll = false,
      this.allowQuery = true,
      FutureOr<Data> Function(RequestContext, ResponseContext) readData})
      : super(readData: readData);

  SqlExpressionBuilder _findBuilder(TQuery query, String name) {
    return query.where.expressionBuilders.firstWhere(
        (b) => b.columnName == name,
        orElse: () => throw ArgumentError(
            '${query.where.runtimeType} has no expression builder for a column named "$name".'));
  }

  void _apply(TQuery query, String name, dynamic value) {
    var builder = _findBuilder(query, name);
    try {
      (builder as dynamic).equals(value);
    } on NoSuchMethodError {
      throw UnsupportedError(
          '${builder.runtimeType} has no `equals` method, so it cannot be given a value from the dynamic query parameter "$name".');
    }
  }

  Future<void> _applyQuery(TQuery query, Map<String, dynamic> params) async {
    if (params == null || params.isEmpty) return;

    if (allowQuery || !params.containsKey('provider')) {
      var queryObj = params['query'];

      if (queryObj is Function(TQuery)) {
        await queryObj(query);
      } else if (queryObj is Map) {
        queryObj.forEach((k, v) {
          if (k == r'$sort') {
            if (v is Map) {
              v.forEach((key, value) {
                var descending = false;
                if (value is String) {
                  descending = value == '-1';
                } else if (value is num) descending = value.toInt() == -1;
                query.orderBy(key.toString(), descending: descending);
              });
            } else if (v is String) {
              query.orderBy(v);
            }
          } else if (k is String &&
              v is! RequestContext &&
              v is! ResponseContext) {
            _apply(query, k, v);
          }
        });
      }
    }
  }

  @override
  Future<List<Data>> readMany(List<Id> ids,
      [Map<String, dynamic> params]) async {
    if (ids.isEmpty) {
      throw ArgumentError.value(ids, 'ids', 'cannot be empty');
    }

    var query = await queryCreator();
    var builder = _findBuilder(query, idField);

    try {
      (builder as dynamic).isIn(ids);
    } on NoSuchMethodError {
      throw UnsupportedError(
          '${builder.runtimeType} `$idField` has no `isIn` method, and therefore does not support `readMany`.');
    }

    await _applyQuery(query, params);
    return await query.get(executor);
  }

  @override
  Future<List<Data>> index([Map<String, dynamic> params]) async {
    var query = await queryCreator();
    await _applyQuery(query, params);
    return await query.get(executor);
  }

  @override
  Future<Data> read(Id id, [Map<String, dynamic> params]) async {
    var query = await queryCreator();
    _apply(query, idField, id);
    await _applyQuery(query, params);
    var result = await query.getOne(executor);
    if (result != null) return result;
    throw AngelHttpException.notFound(message: 'No record found for ID $id');
  }

  @override
  Future<Data> findOne(
      [Map<String, dynamic> params,
      String errorMessage =
          'No record was found matching the given query.']) async {
    var query = await queryCreator();
    await _applyQuery(query, params);
    var result = await query.getOne(executor);
    if (result != null) return result;
    throw AngelHttpException.notFound(message: errorMessage);
  }

  @override
  Future<Data> create(Data data, [Map<String, dynamic> params]) async {
    var query = await queryCreator();

    try {
      (query.values as dynamic).copyFrom(data);
    } on NoSuchMethodError {
      throw UnsupportedError(
          '${query.values.runtimeType} has no `copyFrom` method, but OrmService requires this for insertions.');
    }

    return await query.insert(executor);
  }

  @override
  Future<Data> modify(Id id, Data data, [Map<String, dynamic> params]) {
    return update(id, data, params);
  }

  @override
  Future<Data> update(Id id, Data data, [Map<String, dynamic> params]) async {
    var query = await queryCreator();
    _apply(query, idField, id);
    await _applyQuery(query, params);

    try {
      (query.values as dynamic).copyFrom(data);
    } on NoSuchMethodError {
      throw UnsupportedError(
          '${query.values.runtimeType} has no `copyFrom` method, but OrmService requires this for updates.');
    }

    var result = await query.updateOne(executor);
    if (result != null) return result;
    throw AngelHttpException.notFound(message: 'No record found for ID $id');
  }

  @override
  Future<Data> remove(Id id, [Map<String, dynamic> params]) async {
    var query = await queryCreator();

    if (id == null || id == 'null') {
      // Remove everything...
      if (!(allowRemoveAll == true ||
          params?.containsKey('provider') != true)) {
        throw AngelHttpException.forbidden(
            message: 'Clients are not allowed to delete all items.');
      }
    } else {
      _apply(query, idField, id);
      await _applyQuery(query, params);
    }

    var result = await query.deleteOne(executor);
    if (result != null) return result;
    throw AngelHttpException.notFound(message: 'No record found for ID $id');
  }
}
