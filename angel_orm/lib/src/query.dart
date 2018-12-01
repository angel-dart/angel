import 'dart:async';
import 'annotations.dart';
import 'builder.dart';

/// A base class for objects that compile to SQL queries, typically within an ORM.
abstract class QueryBase<T> {
  String compile({bool includeTableName: false, String preamble});

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

class OrderBy {
  final String key;
  final bool descending;

  const OrderBy(this.key, {this.descending: false});

  String compile() => descending ? '$key DESC' : '$key ASC';
}

/// A SQL `SELECT` query builder.
abstract class Query<T, Where extends QueryWhere> extends QueryBase<T> {
  final List<OrderBy> _orderBy = [];
  String _crossJoin, _groupBy;
  int _limit, _offset;
  JoinBuilder _join;

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

  /// Makes a new [Where] clause.
  Where newWhereClause() {
    throw new UnsupportedError(
        'This instance does not support creating new WHERE clauses.');
  }

  /// Shorthand for calling [where].or with a new [Where] clause.
  void andWhere(void Function(Where) f) {
    var w = newWhereClause();
    f(w);
    where.and(w);
  }

  /// Shorthand for calling [where].or with a new [Where] clause.
  void notWhere(void Function(Where) f) {
    var w = newWhereClause();
    f(w);
    where.not(w);
  }

  /// Shorthand for calling [where].or with a new [Where] clause.
  void orWhere(void Function(Where) f) {
    var w = newWhereClause();
    f(w);
    where.or(w);
  }

  /// Limit the number of rows to return.
  void limit(int n) {
    _limit = n;
  }

  /// Skip a number of rows in the query.
  void offset(int n) {
    _offset = n;
  }

  /// Groups the results by a given key.
  void groupBy(String key) {
    _groupBy = key;
  }

  /// Sorts the results by a key.
  void orderBy(String key, {bool descending: false}) {
    _orderBy.add(new OrderBy(key, descending: descending));
  }

  /// Execute a `CROSS JOIN` (Cartesian product) against another table.
  void crossJoin(String tableName) {
    _crossJoin = tableName;
  }

  /// Execute an `INNER JOIN` against another table.
  void join(String tableName, String localKey, String foreignKey,
      {String op: '='}) {
    _join = new JoinBuilder(
        JoinType.inner, this, tableName, localKey, foreignKey,
        op: op);
  }

  /// Execute a `LEFT JOIN` against another table.
  void leftJoin(String tableName, String localKey, String foreignKey,
      {String op: '='}) {
    _join = new JoinBuilder(
        JoinType.left, this, tableName, localKey, foreignKey,
        op: op);
  }

  /// Execute a `RIGHT JOIN` against another table.
  void rightJoin(String tableName, String localKey, String foreignKey,
      {String op: '='}) {
    _join = new JoinBuilder(
        JoinType.right, this, tableName, localKey, foreignKey,
        op: op);
  }

  /// Execute a `FULL OUTER JOIN` against another table.
  void fullOuterJoin(String tableName, String localKey, String foreignKey,
      {String op: '='}) {
    _join = new JoinBuilder(
        JoinType.full, this, tableName, localKey, foreignKey,
        op: op);
  }

  /// Execute a `SELF JOIN`.
  void selfJoin(String tableName, String localKey, String foreignKey,
      {String op: '='}) {
    _join = new JoinBuilder(
        JoinType.self, this, tableName, localKey, foreignKey,
        op: op);
  }

  @override
  String compile({bool includeTableName: false, String preamble}) {
    var b = new StringBuffer(preamble ?? 'SELECT ');
    var f = fields ?? ['*'];
    if (includeTableName) f = f.map((s) => '$tableName.$s').toList();
    b.write(f.join(', '));
    b.write(' FROM $tableName');
    var whereClause =
        where.compile(tableName: includeTableName ? tableName : null);
    if (whereClause.isNotEmpty) b.write(' WHERE $whereClause');
    if (_limit != null) b.write(' LIMIT $_limit');
    if (_offset != null) b.write(' OFFSET $_offset');
    if (_groupBy != null) b.write(' GROUP BY $_groupBy');
    for (var item in _orderBy) b.write(' ${item.compile()}');
    if (_crossJoin != null) b.write(' CROSS JOIN $_crossJoin');
    if (_join != null) b.write(' ${_join.compile()}');
    return b.toString();
  }
}

/// Builds a SQL `WHERE` clause.
abstract class QueryWhere {
  final Set<QueryWhere> _and = new Set();
  final Set<QueryWhere> _not = new Set();
  final Set<QueryWhere> _or = new Set();

  Iterable<SqlExpressionBuilder> get expressionBuilders;

  void and(QueryWhere other) {
    _and.add(other);
  }

  void not(QueryWhere other) {
    _not.add(other);
  }

  void or(QueryWhere other) {
    _or.add(other);
  }

  String compile({String tableName}) {
    var b = new StringBuffer();
    int i = 0;

    for (var builder in expressionBuilders) {
      var key = builder.columnName;
      if (tableName != null) key = '$tableName.$key';
      if (builder.hasValue) {
        if (i++ > 0) b.write(' AND ');
        b.write('$key ${builder.compile()}');
      }
    }

    for (var other in _and) {
      var sql = other.compile();
      if (sql.isNotEmpty) b.write(' AND $sql');
    }

    for (var other in _not) {
      var sql = other.compile();
      if (sql.isNotEmpty) b.write(' NOT $sql');
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
  String compile({bool includeTableName: false, String preamble}) {
    var selector = all == true ? 'UNION ALL' : 'UNION';
    return '(${left.compile(includeTableName: includeTableName)}) $selector (${right.compile(includeTableName: includeTableName)})';
  }
}

/// Builds a SQL `JOIN` query.
class JoinBuilder {
  final JoinType type;
  final Query from;
  final String to, key, value, op;

  JoinBuilder(this.type, this.from, this.to, this.key, this.value,
      {this.op: '='});

  String compile() {
    var b = new StringBuffer();
    var left = '${from.tableName}.$key';
    var right = '$to.$value';

    switch (type) {
      case JoinType.inner:
        b.write(' INNER JOIN');
        break;
      case JoinType.left:
        b.write(' LEFT JOIN');
        break;
      case JoinType.right:
        b.write(' RIGHT JOIN');
        break;
      case JoinType.full:
        b.write(' FULL OUTER JOIN');
        break;
      case JoinType.self:
        b.write(' SELF JOIN');
        break;
    }

    b.write(' $to ON $left$op$right');
    return b.toString();
  }
}

class JoinOn {
  final SqlExpressionBuilder key;
  final SqlExpressionBuilder value;

  JoinOn(this.key, this.value);
}

/// An abstract interface that performs queries.
///
/// This class should be implemented.
abstract class QueryExecutor {
  const QueryExecutor();

  Future<List<List>> query(String query);
}
