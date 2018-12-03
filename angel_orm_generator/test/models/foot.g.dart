// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.foot;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class FootQuery extends Query<Foot, FootQueryWhere> {
  @override
  final FootQueryValues values = new FootQueryValues();

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
  FootQueryWhere newWhereClause() {
    return new FootQueryWhere();
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

class FootQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  int get legId {
    return (values['leg_id'] as int);
  }

  void set legId(int value) => values['leg_id'] = value;
  int get nToes {
    return (values['n_toes'] as int);
  }

  void set nToes(int value) => values['n_toes'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  void set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  void set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Foot model) {
    values.addAll({
      'leg_id': model.legId,
      'n_toes': model.nToes,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
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
