const Orm orm = const Orm();

class Orm {
  final String tableName;

  const Orm({this.tableName});
}

class CanJoin {
  final Type type;
  final String foreignKey;
  final JoinType joinType;

  const CanJoin(this.type, this.foreignKey, {this.joinType: JoinType.full});
}

/// The various types of [Join].
enum JoinType { join, left, right, full, self }
