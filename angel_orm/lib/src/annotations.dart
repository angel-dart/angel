const Orm orm = const Orm();

class Orm {
  final String tableName;

  const Orm({this.tableName});
}

class Join {
  final Type against;
  final String foreignKey;
  final JoinType type;

  const Join(this.against, this.foreignKey, {this.type: JoinType.inner});
}

/// The various types of [Join].
enum JoinType { inner, left, right, full, self }
