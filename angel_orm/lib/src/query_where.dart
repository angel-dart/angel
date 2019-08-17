import 'builder.dart';

/// Builds a SQL `WHERE` clause.
abstract class QueryWhere {
  final Set<QueryWhere> _and = Set();
  final Set<QueryWhere> _not = Set();
  final Set<QueryWhere> _or = Set();

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
    var b = StringBuffer();
    int i = 0;

    for (var builder in expressionBuilders) {
      var key = builder.columnName;
      if (tableName != null) key = '$tableName.$key';
      if (builder.hasValue) {
        if (i++ > 0) b.write(' AND ');
        if (builder is DateTimeSqlExpressionBuilder ||
            (builder is JsonSqlExpressionBuilder && builder.hasRaw)) {
          if (tableName != null) b.write('$tableName.');
          b.write(builder.compile());
        } else {
          b.write('$key ${builder.compile()}');
        }
      }
    }

    for (var other in _and) {
      var sql = other.compile();
      if (sql.isNotEmpty) b.write(' AND ($sql)');
    }

    for (var other in _not) {
      var sql = other.compile();
      if (sql.isNotEmpty) b.write(' NOT ($sql)');
    }

    for (var other in _or) {
      var sql = other.compile();
      if (sql.isNotEmpty) b.write(' OR ($sql)');
    }

    return b.toString();
  }
}
