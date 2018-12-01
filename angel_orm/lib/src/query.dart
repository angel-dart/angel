import 'dart:async';
import 'builder.dart';

/// A base class for objects that compile to SQL queries, typically within an ORM.
abstract class QueryBase<T> {
  String compile();

  T deserialize(List row);

  Future<List<T>> get(QueryExecutor executor) async {
    var sql = compile();
    return executor.query(sql).then((it) => it.map(deserialize).toList());
  }

  Future<T> getOne(QueryExecutor executor) {
    return get(executor).then((it) => it.isEmpty ? null : it.first);
  }

  Union<T> union(QueryBase<T> other) {
    return new Union(this, other);
  }

  Union<T> unionAll(QueryBase<T> other) {
    return new Union(this, other, all: true);
  }
}

/// A SQL `SELECT` query builder.
abstract class Query<T, Where extends QueryWhere> extends QueryBase<T> {
  /// The table against which to execute this query.
  String get tableName;

  /// The list of fields returned by this query.
  ///
  /// If it's `null`, then this query will perform a `SELECT *`.
  List<String> get fields;

  /// A reference to an abstract query builder.
  ///
  /// This is often a generated class.
  Where get where;

  @override
  String compile() {
    var b = new StringBuffer('SELECT ');
    if (fields == null)
      b.write('*');
    else
      b.write(fields.join(', '));
    b.write(' FROM $tableName');
    var whereClause = where.compile();
    if (whereClause.isNotEmpty) b.write(' WHERE $whereClause');
    return b.toString();
  }
}

/// Builds a SQL `WHERE` clause.
abstract class QueryWhere {
  final Set<QueryWhere> _and = new Set();
  final Set<QueryWhere> _or = new Set();

  Map<String, SqlExpressionBuilder> get expressionBuilders;

  void and(QueryWhere other) {
    _and.add(other);
  }

  void or(QueryWhere other) {
    _or.add(other);
  }

  String compile() {
    var b = new StringBuffer();
    int i = 0;

    for (var entry in expressionBuilders.entries) {
      var key = entry.key, builder = entry.value;
      if (builder.hasValue) {
        if (i++ > 0) b.write(' AND ');
        b.write('$key ${builder.compile()}');
      }
    }

    for (var other in _and) {
      var sql = other.compile();
      if (sql.isNotEmpty) b.write(' AND $sql');
    }

    for (var other in _or) {
      var sql = other.compile();
      if (sql.isNotEmpty) b.write(' OR $sql');
    }

    return b.toString();
  }
}

/// Represents the `UNION` of two subqueries.
class Union<T> extends QueryBase<T> {
  final QueryBase<T> left, right;
  final bool all;

  Union(this.left, this.right, {this.all: false});

  @override
  T deserialize(List row) => left.deserialize(row);

  @override
  String compile() {
    var selector = all == true ? 'UNION ALL' : 'UNION';
    return '(${left.compile()}) $selector (${right.compile()})';
  }
}

/// An abstract interface that performs queries.
///
/// This class should be implemented.
abstract class QueryExecutor {
  const QueryExecutor();

  Future<List<List>> query(String query);
}
