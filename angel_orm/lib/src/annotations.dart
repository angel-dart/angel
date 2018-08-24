const ORM orm = const ORM();

class ORM {
  final String tableName;

  const ORM([this.tableName]);
}

class CanJoin {
  final Type type;
  final String foreignKey;
  final JoinType joinType;

  const CanJoin(this.type, this.foreignKey, {this.joinType: JoinType.full});
}

/// The various types of [Join].
enum JoinType { join, left, right, full, self }
