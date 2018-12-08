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
    return 'feet';
  }

  @override
  get fields {
    return const ['id', 'leg_id', 'n_toes', 'created_at', 'updated_at'];
  }

  @override
  FootQueryWhere newWhereClause() {
    return new FootQueryWhere();
  }

  static Foot parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Foot(
        id: row[0].toString(),
        legId: (row[1] as int),
        nToes: (row[2] as int),
        createdAt: (row[3] as DateTime),
        updatedAt: (row[4] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
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

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class FootSerializer {
  static Foot fromMap(Map map) {
    return new Foot(
        id: map['id'] as String,
        legId: map['leg_id'] as int,
        nToes: map['n_toes'] as int,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null);
  }

  static Map<String, dynamic> toMap(_Foot model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'leg_id': model.legId,
      'n_toes': model.nToes,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class FootFields {
  static const List<String> allFields = const <String>[
    id,
    legId,
    nToes,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String legId = 'leg_id';

  static const String nToes = 'n_toes';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
