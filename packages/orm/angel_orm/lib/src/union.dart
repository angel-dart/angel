import 'query_base.dart';

/// Represents the `UNION` of two subqueries.
class Union<T> extends QueryBase<T> {
  /// The subject(s) of this binary operation.
  final QueryBase<T> left, right;

  /// Whether this is a `UNION ALL` operation.
  final bool all;

  @override
  final String tableName;

  Union(this.left, this.right, {this.all = false, String tableName})
      : this.tableName = tableName ?? left.tableName {
    substitutionValues
      ..addAll(left.substitutionValues)
      ..addAll(right.substitutionValues);
  }

  @override
  List<String> get fields => left.fields;

  @override
  T deserialize(List row) => left.deserialize(row);

  @override
  String compile(Set<String> trampoline,
      {bool includeTableName = false,
      String preamble,
      bool withFields = true}) {
    var selector = all == true ? 'UNION ALL' : 'UNION';
    var t1 = Set<String>.from(trampoline);
    var t2 = Set<String>.from(trampoline);
    return '(${left.compile(t1, includeTableName: includeTableName)}) $selector (${right.compile(t2, includeTableName: includeTableName)})';
  }
}
