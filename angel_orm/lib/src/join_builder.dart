import 'annotations.dart';
import 'query.dart';

/// Builds a SQL `JOIN` query.
class JoinBuilder {
  final JoinType type;
  final Query from;
  final String to, key, value, op, alias;
  final List<String> additionalFields;

  JoinBuilder(this.type, this.from, this.to, this.key, this.value,
      {this.op = '=', this.alias, this.additionalFields = const []}) {
    assert(to != null,
        'computation of this join threw an error, and returned null.');
  }

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

  String compile(Set<String> trampoline) {
    if (to == null) return null;
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

    b.write(' $to');
    if (alias != null) b.write(' $alias');
    b.write(' ON $left$op$right');
    return b.toString();
  }
}