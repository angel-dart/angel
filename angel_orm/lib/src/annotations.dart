const ORM orm = const ORM();

class ORM {
  final String tableName;
  const ORM([this.tableName]);
}

class CanJoin {
  final Type type;
  final String foreignKey;
  const CanJoin(this.type, this.foreignKey);
}