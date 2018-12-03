// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.leg;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class LegQuery extends Query<Leg, LegQueryWhere> {
  @override
  final LegQueryValues values = new LegQueryValues();

  @override
  final LegQueryWhere where = new LegQueryWhere();

  @override
  get tableName {
    return 'legs';
  }

  @override
  get fields {
    return const ['id', 'name', 'created_at', 'updated_at'];
  }

  @override
  LegQueryWhere newWhereClause() {
    return new LegQueryWhere();
  }

  static Leg parseRow(List row) {
    var model = new Leg(
        id: row[0].toString(),
        name: (row[1] as String),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
    if (row.length > 4) {
      model = model.copyWith(foot: FootQuery.parseRow(row.skip(4).toList()));
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }

  @override
  get(executor) {
    return super.get(executor);
  }
}

class LegQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final StringSqlExpressionBuilder name =
      new StringSqlExpressionBuilder('name');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [id, name, createdAt, updatedAt];
  }
}

class LegQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  String get name {
    return (values['name'] as String);
  }

  void set name(String value) => values['name'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  void set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  void set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Leg model) {
    values.addAll({
      'name': model.name,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Leg extends _Leg {
  Leg({this.id, this.foot, this.name, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final Foot foot;

  @override
  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Leg copyWith(
      {String id,
      Foot foot,
      String name,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Leg(
        id: id ?? this.id,
        foot: foot ?? this.foot,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Leg &&
        other.id == id &&
        other.foot == foot &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, foot, name, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return LegSerializer.toMap(this);
  }
}
