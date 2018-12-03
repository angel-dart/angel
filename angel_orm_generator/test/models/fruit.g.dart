// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.fruit;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class FruitQuery extends Query<Fruit, FruitQueryWhere> {
  @override
  final FruitQueryWhere where = new FruitQueryWhere();

  @override
  get tableName {
    return 'fruits';
  }

  @override
  get fields {
    return FruitFields.allFields;
  }

  @override
  deserialize(List row) {
    return new Fruit(
        id: row[0].toString(),
        treeId: (row[1] as int),
        commonName: (row[2] as String),
        createdAt: (row[3] as DateTime),
        updatedAt: (row[4] as DateTime));
  }
}

class FruitQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final NumericSqlExpressionBuilder<int> treeId =
      new NumericSqlExpressionBuilder<int>('tree_id');

  final StringSqlExpressionBuilder commonName =
      new StringSqlExpressionBuilder('common_name');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [id, treeId, commonName, createdAt, updatedAt];
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Fruit extends _Fruit {
  Fruit(
      {this.id, this.treeId, this.commonName, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final int treeId;

  @override
  final String commonName;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Fruit copyWith(
      {String id,
      int treeId,
      String commonName,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Fruit(
        id: id ?? this.id,
        treeId: treeId ?? this.treeId,
        commonName: commonName ?? this.commonName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Fruit &&
        other.id == id &&
        other.treeId == treeId &&
        other.commonName == commonName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, treeId, commonName, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return FruitSerializer.toMap(this);
  }
}
