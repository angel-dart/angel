// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.leg;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class LegQuery extends Query<Leg, LegQueryWhere> {
  LegQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = LegQueryWhere(this);
  }

  @override
  final LegQueryValues values = LegQueryValues();

  LegQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'legs';
  }

  @override
  get fields {
    return const ['id'];
  }

  @override
  LegQueryWhere get where {
    return _where;
  }

  @override
  LegQueryWhere newWhereClause() {
    return LegQueryWhere(this);
  }

  static Leg parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Leg(id: row[0].toString());
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class LegQueryWhere extends QueryWhere {
  LegQueryWhere(LegQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id');

  final NumericSqlExpressionBuilder<int> id;

  @override
  get expressionBuilders {
    return [id];
  }
}

class LegQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  void copyFrom(Leg model) {}
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
  final dynamic foot;

  @override
  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Leg copyWith(
      {String id,
      dynamic foot,
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

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class LegSerializer {
  static Leg fromMap(Map map) {
    return new Leg(
        id: map['id'] as String,
        foot: map['foot'] as dynamic,
        name: map['name'] as String,
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

  static Map<String, dynamic> toMap(_Leg model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'foot': model.foot,
      'name': model.name,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class LegFields {
  static const List<String> allFields = <String>[
    id,
    foot,
    name,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String foot = 'foot';

  static const String name = 'name';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
