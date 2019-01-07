import 'dart:async';
import 'package:charcode/ascii.dart';
import 'annotations.dart';
import 'builder.dart';

bool isAscii(int ch) => ch >= $nul && ch <= $del;

/// A base class for objects that compile to SQL queries, typically within an ORM.
abstract class QueryBase<T> {
  final Map<String, dynamic> substitutionValues = {};

  /// The list of fields returned by this query.
  ///
  /// If it's `null`, then this query will perform a `SELECT *`.
  List<String> get fields;

  /// A String of all [fields], joined by a comma (`,`).
  String get fieldSet => fields.join(', ');

  String compile(
      {bool includeTableName: false, String preamble, bool withFields: true});

  T deserialize(List row);

  Future<List<T>> get(QueryExecutor executor) async {
    var sql = compile();
    return executor
        .query(sql, substitutionValues)
        .then((it) => it.map(deserialize).toList());
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

/// The ORM prefers using substitution values, which allow for prepared queries,
/// and prevent SQL injection attacks.
@deprecated
String toSql(Object obj, {bool withQuotes: true}) {
  if (obj is DateTime) {
    return withQuotes ? "'${dateYmdHms.format(obj)}'" : dateYmdHms.format(obj);
  } else if (obj is bool) {
    return obj ? 'TRUE' : 'FALSE';
  } else if (obj == null) {
    return 'NULL';
  } else if (obj is String) {
    var b = new StringBuffer();
    var escaped = false;
    var it = obj.runes.iterator;

    while (it.moveNext()) {
      if (it.current == $nul)
        continue; // Skip null byte
      else if (it.current == $single_quote) {
        escaped = true;
        b.write('\\x');
        b.write(it.current.toRadixString(16).padLeft(2, '0'));
      } else if (isAscii(it.current)) {
        b.writeCharCode(it.current);
      } else if (it.currentSize == 1) {
        escaped = true;
        b.write('\\u');
        b.write(it.current.toRadixString(16).padLeft(4, '0'));
      } else if (it.currentSize == 2) {
        escaped = true;
        b.write('\\U');
        b.write(it.current.toRadixString(16).padLeft(8, '0'));
      } else {
        throw new UnsupportedError(
            'toSql() cannot encode a rune of size (${it.currentSize})');
      }
    }

    if (!withQuotes)
      return b.toString();
    else if (escaped)
      return "E'$b'";
    else
      return "'$b'";
  } else {
    return obj.toString();
  }
}

/// A SQL `SELECT` query builder.
abstract class Query<T, Where extends QueryWhere> extends QueryBase<T> {
  final List<JoinBuilder> _joins = [];
  final Map<String, int> _names = {};
  final List<OrderBy> _orderBy = [];

  String _crossJoin, _groupBy;
  int _limit, _offset;

  /// The table against which to execute this query.
  String get tableName;

  /// A reference to an abstract query builder.
  ///
  /// This is usually a generated class.
  Where get where;

  /// A set of values, for an insertion or update.
  ///
  /// This is usually a generated class.
  QueryValues get values;

  /// Preprends the [tableName] to the [String], [s].
  String adornWithTableName(String s) => '$tableName.$s';

  /// Returns a unique version of [name], which will not produce a collision within
  /// the context of this [query].
  String reserveName(String name) {
    var n = _names[name] ??= 0;
    _names[name]++;
    return n == 0 ? name : '${name}$n';
  }

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

  String _joinAlias() => 'a${_joins.length}';

  /// Execute an `INNER JOIN` against another table.
  void join(String tableName, String localKey, String foreignKey,
      {String op: '=', List<String> additionalFields: const []}) {
    _joins.add(new JoinBuilder(
        JoinType.inner, this, tableName, localKey, foreignKey,
        op: op, alias: _joinAlias(), additionalFields: additionalFields));
  }

  /// Execute a `LEFT JOIN` against another table.
  void leftJoin(String tableName, String localKey, String foreignKey,
      {String op: '=', List<String> additionalFields: const []}) {
    _joins.add(new JoinBuilder(
        JoinType.left, this, tableName, localKey, foreignKey,
        op: op, alias: _joinAlias(), additionalFields: additionalFields));
  }

  /// Execute a `RIGHT JOIN` against another table.
  void rightJoin(String tableName, String localKey, String foreignKey,
      {String op: '=', List<String> additionalFields: const []}) {
    _joins.add(new JoinBuilder(
        JoinType.right, this, tableName, localKey, foreignKey,
        op: op, alias: _joinAlias(), additionalFields: additionalFields));
  }

  /// Execute a `FULL OUTER JOIN` against another table.
  void fullOuterJoin(String tableName, String localKey, String foreignKey,
      {String op: '=', List<String> additionalFields: const []}) {
    _joins.add(new JoinBuilder(
        JoinType.full, this, tableName, localKey, foreignKey,
        op: op, alias: _joinAlias(), additionalFields: additionalFields));
  }

  /// Execute a `SELF JOIN`.
  void selfJoin(String tableName, String localKey, String foreignKey,
      {String op: '=', List<String> additionalFields: const []}) {
    _joins.add(new JoinBuilder(
        JoinType.self, this, tableName, localKey, foreignKey,
        op: op, alias: _joinAlias(), additionalFields: additionalFields));
  }

  @override
  String compile(
      {bool includeTableName: false,
      String preamble,
      bool withFields: true,
      String fromQuery}) {
    includeTableName = includeTableName || _joins.isNotEmpty;
    var b = new StringBuffer(preamble ?? 'SELECT');
    b.write(' ');
    List<String> f;

    if (fields == null) {
      f = ['*'];
    } else {
      f = new List<String>.from(
          fields.map((s) => includeTableName ? '$tableName.$s' : s));
      _joins.forEach((j) {
        f
          ..add(j.fieldName)
          ..addAll(j.additionalFields.map((s) => j.nameFor(s)));
      });
    }
    if (withFields) b.write(f.join(', '));
    fromQuery ??= tableName;
    b.write(' FROM $fromQuery');

    // No joins if it's not a select.
    if (preamble == null) {
      if (_crossJoin != null) b.write(' CROSS JOIN $_crossJoin');
      for (var join in _joins) b.write(' ${join.compile()}');
    }

    var whereClause =
        where.compile(tableName: includeTableName ? tableName : null);
    if (whereClause.isNotEmpty) b.write(' WHERE $whereClause');
    if (_limit != null) b.write(' LIMIT $_limit');
    if (_offset != null) b.write(' OFFSET $_offset');
    if (_groupBy != null) b.write(' GROUP BY $_groupBy');
    for (var item in _orderBy) b.write(' ${item.compile()}');
    return b.toString();
  }

  @override
  Future<T> getOne(QueryExecutor executor) {
    //limit(1);
    return super.getOne(executor);
  }

  Future<List<T>> delete(QueryExecutor executor) {
    var sql = compile(preamble: 'DELETE', withFields: false);

    if (_joins.isEmpty) {
      return executor
          .query(
              sql, substitutionValues, fields.map(adornWithTableName).toList())
          .then((it) => it.map(deserialize).toList());
    } else {
      return executor.transaction(() async {
        // TODO: Can this be done with just *one* query?
        var existing = await get(executor);
        //var sql = compile(preamble: 'SELECT $tableName.id', withFields: false);
        return executor.query(sql, substitutionValues).then((_) => existing);
      });
    }
  }

  Future<T> deleteOne(QueryExecutor executor) {
    return delete(executor).then((it) => it.isEmpty ? null : it.first);
  }

  Future<T> insert(QueryExecutor executor) {
    var insertion = values.compileInsert(this, tableName);

    if (insertion == null) {
      throw new StateError('No values have been specified for update.');
    } else {
      // TODO: How to do this in a non-Postgres DB?
      var returning = fields.map(adornWithTableName).join(', ');
      var sql = compile();
      sql = 'WITH $tableName as ($insertion RETURNING $returning) ' + sql;
      return executor
          .query(sql, substitutionValues)
          .then((it) => it.isEmpty ? null : deserialize(it.first));
    }
  }

  Future<List<T>> update(QueryExecutor executor) async {
    var updateSql = new StringBuffer('UPDATE $tableName ');
    var valuesClause = values.compileForUpdate(this);

    if (valuesClause == null) {
      throw new StateError('No values have been specified for update.');
    } else {
      updateSql.write(' $valuesClause');
      var whereClause = where.compile();
      if (whereClause.isNotEmpty) updateSql.write(' WHERE $whereClause');
      if (_limit != null) updateSql.write(' LIMIT $_limit');

      var returning = fields.map(adornWithTableName).join(', ');
      var sql = compile();
      sql = 'WITH $tableName as ($updateSql RETURNING $returning) ' + sql;

      return executor
          .query(sql, substitutionValues)
          .then((it) => it.map(deserialize).toList());
    }
  }

  Future<T> updateOne(QueryExecutor executor) {
    return update(executor).then((it) => it.isEmpty ? null : it.first);
  }
}

abstract class QueryValues {
  Map<String, dynamic> toMap();

  String compileInsert(Query query, String tableName) {
    var data = toMap();
    if (data.isEmpty) return null;

    var fieldSet = data.keys.join(', ');
    var b = new StringBuffer('INSERT INTO $tableName ($fieldSet) VALUES (');
    int i = 0;

    for (var entry in data.entries) {
      if (i++ > 0) b.write(', ');

      var name = query.reserveName(entry.key);
      query.substitutionValues[name] = entry.value;
      b.write('@$name');
    }

    b.write(')');
    return b.toString();
  }

  String compileForUpdate(Query query) {
    var data = toMap();
    if (data.isEmpty) return null;
    var b = new StringBuffer('SET');
    int i = 0;

    for (var entry in data.entries) {
      if (i++ > 0) b.write(',');
      b.write(' ');
      b.write(entry.key);
      b.write('=');

      var name = query.reserveName(entry.key);
      query.substitutionValues[name] = entry.value;
      b.write('@$name');
    }
    return b.toString();
  }
}

/// A [QueryValues] implementation that simply writes to a [Map].
class MapQueryValues extends QueryValues {
  final Map<String, dynamic> values = {};

  @override
  Map<String, dynamic> toMap() => values;
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
        if (builder is DateTimeSqlExpressionBuilder) {
          if (tableName != null) b.write('$tableName.');
          b.write(builder.compile());
        } else {
          b.write('$key ${builder.compile()}');
        }
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

  Union(this.left, this.right, {this.all: false}) {
    substitutionValues
      ..addAll(left.substitutionValues)
      ..addAll(right.substitutionValues);
  }

  @override
  List<String> get fields => left.fields;

  @override
  T deserialize(List row) => left.deserialize(row);

  @override
  String compile(
      {bool includeTableName: false, String preamble, bool withFields: true}) {
    var selector = all == true ? 'UNION ALL' : 'UNION';
    return '(${left.compile(includeTableName: includeTableName)}) $selector (${right.compile(includeTableName: includeTableName)})';
  }
}

/// Builds a SQL `JOIN` query.
class JoinBuilder {
  final JoinType type;
  final Query from;
  final String to, key, value, op, alias;
  final List<String> additionalFields;

  JoinBuilder(this.type, this.from, this.to, this.key, this.value,
      {this.op: '=', this.alias, this.additionalFields: const []});

  String get fieldName {
    var right = '$to.$value';
    if (alias != null) right = '$alias.$value';
    return right;
  }

  String nameFor(String name) {
    var right = '$to.$name';
    if (alias != null) right = '$alias.$name';
    return right;
  }

  String compile() {
    var b = new StringBuffer();
    var left = '${from.tableName}.$key';
    var right = fieldName;

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

    b.write(' $to');
    if (alias != null) b.write(' $alias');
    b.write(' ON $left$op$right');
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

  Future<List<List>> query(
      String query, Map<String, dynamic> substitutionValues,
      [List<String> returningFields]);

  Future<T> transaction<T>(FutureOr<T> f());
}
