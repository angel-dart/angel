// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.foot;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class FootQuery extends Query<Foot, FootQueryWhere> {
  @override
  final FootQueryWhere where = new FootQueryWhere();

  @override
  get tableName {
    return 'foots';
  }

  @override
  get fields {
    return FootFields.allFields;
  }

  @override
  deserialize(List row) {
    return new Foot(
        id: row[0].toString(),
        legId: (row[1] as int),
        nToes: (row[2] as int),
        createdAt: (row[3] as DateTime),
        updatedAt: (row[4] as DateTime));
  }
}

class FootQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final NumericSqlExpressionBuilder<int> legId =
      new NumericSqlExpressionBuilder<int>('leg_id');

  final NumericSqlExpressionBuilder<int> nToes =
      new NumericSqlExpressionBuilder<int>('n_toes');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [id, legId, nToes, createdAt, updatedAt];
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Foot extends _Foot {
  Foot({this.id, this.legId, this.nToes, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final int legId;

  @override
  final int nToes;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Foot copyWith(
      {String id,
      int legId,
      int nToes,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Foot(
        id: id ?? this.id,
        legId: legId ?? this.legId,
        nToes: nToes ?? this.nToes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Foot &&
        other.id == id &&
        other.legId == legId &&
        other.nToes == nToes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, legId, nToes, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return FootSerializer.toMap(this);
  }
}
