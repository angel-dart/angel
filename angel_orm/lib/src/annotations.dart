const Orm mongoDBOrm = const Orm(OrmType.mongoDB);

const Orm rethinkDBOrm = const Orm(OrmType.rethinkDB);

const Orm postgreSqlOrm = const Orm(OrmType.postgreSql);

const Orm mySqlOrm = const Orm(OrmType.mySql);

class Orm {
  final OrmType type;
  final String tableName;

  const Orm(this.type, {this.tableName});
}

enum OrmType {
  mongoDB,
  rethinkDB,
  mySql,
  postgreSql,
}

class CanJoin {
  final Type type;
  final String foreignKey;
  final JoinType joinType;

  const CanJoin(this.type, this.foreignKey, {this.joinType: JoinType.full});
}

/// The various types of [Join].
enum JoinType { join, left, right, full, self }
