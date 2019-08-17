import 'dart:async';
import 'query_executor.dart';
import 'union.dart';

/// A base class for objects that compile to SQL queries, typically within an ORM.
abstract class QueryBase<T> {
  /// Casts to perform when querying the database.
  Map<String, String> get casts => {};

  /// Values to insert into a prepared statement.
  final Map<String, dynamic> substitutionValues = {};

  /// The table against which to execute this query.
  String get tableName;

  /// The list of fields returned by this query.
  ///
  /// If it's `null`, then this query will perform a `SELECT *`.
  List<String> get fields;

  /// A String of all [fields], joined by a comma (`,`).
  String get fieldSet => fields.map((k) {
        var cast = casts[k];
        return cast == null ? k : 'CAST ($k AS $cast)';
      }).join(', ');

  String compile(Set<String> trampoline,
      {bool includeTableName = false, String preamble, bool withFields = true});

  T deserialize(List row);

  Future<List<T>> get(QueryExecutor executor) async {
    var sql = compile(Set());
    return executor
        .query(tableName, sql, substitutionValues)
        .then((it) => it.map(deserialize).toList());
  }

  Future<T> getOne(QueryExecutor executor) {
    return get(executor).then((it) => it.isEmpty ? null : it.first);
  }

  Union<T> union(QueryBase<T> other) {
    return Union(this, other);
  }

  Union<T> unionAll(QueryBase<T> other) {
    return Union(this, other, all: true);
  }
}
