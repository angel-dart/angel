const Orm orm = const Orm();

class Orm {
  /// The name of the table to query.
  /// 
  /// Inferred if not present.
  final String tableName;
  
  /// Whether to generate migrations for this model.
  /// 
  /// Defaults to [:true:].
  final bool generateMigrations;

  const Orm({this.tableName, this.generateMigrations: true});
}

class Join {
  final Type against;
  final String foreignKey;
  final JoinType type;

  const Join(this.against, this.foreignKey, {this.type: JoinType.inner});
}

/// The various types of [Join].
enum JoinType { inner, left, right, full, self }
