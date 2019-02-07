// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'has_car.dart';

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class HasCarMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('has_cars', (table) {
      table.serial('id')..primaryKey();
      table.integer('type');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('has_cars');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class HasCarQuery extends Query<HasCar, HasCarQueryWhere> {
  HasCarQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = HasCarQueryWhere(this);
  }

  @override
  final HasCarQueryValues values = HasCarQueryValues();

  HasCarQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'has_cars';
  }

  @override
  get fields {
    return const ['id', 'type', 'created_at', 'updated_at'];
  }

  @override
  HasCarQueryWhere get where {
    return _where;
  }

  @override
  HasCarQueryWhere newWhereClause() {
    return HasCarQueryWhere(this);
  }

  static HasCar parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = HasCar(
        id: row[0].toString(),
        type: CarType.values[(row[1] as int)],
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class HasCarQueryWhere extends QueryWhere {
  HasCarQueryWhere(HasCarQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        type = EnumSqlExpressionBuilder<CarType>(query, 'type', (v) => v.index),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final EnumSqlExpressionBuilder<CarType> type;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, type, createdAt, updatedAt];
  }
}

class HasCarQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  CarType get type {
    return CarType.values[(values['type'] as int)];
  }

  set type(CarType value) => values['type'] = value.index;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(HasCar model) {
    type = model.type;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class HasCar extends _HasCar {
  HasCar({this.id, @required this.type, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final CarType type;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  HasCar copyWith(
      {String id, CarType type, DateTime createdAt, DateTime updatedAt}) {
    return new HasCar(
        id: id ?? this.id,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _HasCar &&
        other.id == id &&
        other.type == type &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, type, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return HasCarSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class HasCarSerializer {
  static HasCar fromMap(Map map) {
    if (map['type'] == null) {
      throw new FormatException("Missing required field 'type' on HasCar.");
    }

    return new HasCar(
        id: map['id'] as String,
        type: map['type'] is CarType
            ? (map['type'] as CarType)
            : (map['type'] is int ? CarType.values[map['type'] as int] : null),
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

  static Map<String, dynamic> toMap(_HasCar model) {
    if (model == null) {
      return null;
    }
    if (model.type == null) {
      throw new FormatException("Missing required field 'type' on HasCar.");
    }

    return {
      'id': model.id,
      'type': model.type == null ? null : CarType.values.indexOf(model.type),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class HasCarFields {
  static const List<String> allFields = <String>[
    id,
    type,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String type = 'type';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
