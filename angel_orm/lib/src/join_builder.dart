import 'annotations.dart';
import 'query.dart';

/// Builds a SQL `JOIN` query.
class JoinBuilder {
  final JoinType type;
  final Query from;
  final String key, value, op, alias;
  final bool aliasAllFields;

  /// A callback to produces the expression to join against, i.e.
  /// a table name, or the result of compiling a query.
  final String Function() to;
  final List<String> additionalFields;

  JoinBuilder(this.type, this.from, this.to, this.key, this.value,
      {this.op = '=',
      this.alias,
      this.additionalFields = const [],
      this.aliasAllFields = false}) {
    assert(to != null,
        'computation of this join threw an error, and returned null.');
  }

  String get fieldName {
    var v = value;
    if (aliasAllFields) {
      v = '${alias}_$v';
    }
    var right = '${from.tableName}.$v';
    if (alias != null) right = '$alias.$v';
    return right;
  }

  String nameFor(String name) {
    if (aliasAllFields) name = '${alias}_$name';
    var right = '${from.tableName}.$name';
    if (alias != null) right = '$alias.$name';
    return right;
  }

  String compile(Set<String> trampoline) {
    var compiledTo = to();
    if (compiledTo == null) return null;
    var b = StringBuffer();
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

    b.write(' $compiledTo');
    if (alias != null) b.write(' $alias');
    b.write(' ON $left$op$right');
    return b.toString();
  }
}
