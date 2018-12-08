// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.car;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class CarQuery extends Query<Car, CarQueryWhere> {
  @override
  final CarQueryValues values = new CarQueryValues();

  @override
  final CarQueryWhere where = new CarQueryWhere();

  @override
  get tableName {
    return 'cars';
  }

  @override
  get fields {
    return const [
      'id',
      'make',
      'description',
      'family_friendly',
      'recalled_at',
      'created_at',
      'updated_at'
    ];
  }

  @override
  CarQueryWhere newWhereClause() {
    return new CarQueryWhere();
  }

  static Car parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Car(
        id: row[0].toString(),
        make: (row[1] as String),
        description: (row[2] as String),
        familyFriendly: (row[3] as bool),
        recalledAt: (row[4] as DateTime),
        createdAt: (row[5] as DateTime),
        updatedAt: (row[6] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class CarQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final StringSqlExpressionBuilder make =
      new StringSqlExpressionBuilder('make');

  final StringSqlExpressionBuilder description =
      new StringSqlExpressionBuilder('description');

  final BooleanSqlExpressionBuilder familyFriendly =
      new BooleanSqlExpressionBuilder('family_friendly');

  final DateTimeSqlExpressionBuilder recalledAt =
      new DateTimeSqlExpressionBuilder('recalled_at');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [
      id,
      make,
      description,
      familyFriendly,
      recalledAt,
      createdAt,
      updatedAt
    ];
  }
}

class CarQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  String get make {
    return (values['make'] as String);
  }

  void set make(String value) => values['make'] = value;
  String get description {
    return (values['description'] as String);
  }

  void set description(String value) => values['description'] = value;
  bool get familyFriendly {
    return (values['family_friendly'] as bool);
  }

  void set familyFriendly(bool value) => values['family_friendly'] = value;
  DateTime get recalledAt {
    return (values['recalled_at'] as DateTime);
  }

  void set recalledAt(DateTime value) => values['recalled_at'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  void set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  void set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Car model) {
    values.addAll({
      'make': model.make,
      'description': model.description,
      'family_friendly': model.familyFriendly,
      'recalled_at': model.recalledAt,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Car extends _Car {
  Car(
      {this.id,
      this.make,
      this.description,
      this.familyFriendly,
      this.recalledAt,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final String make;

  @override
  final String description;

  @override
  final bool familyFriendly;

  @override
  final DateTime recalledAt;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Car copyWith(
      {String id,
      String make,
      String description,
      bool familyFriendly,
      DateTime recalledAt,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Car(
        id: id ?? this.id,
        make: make ?? this.make,
        description: description ?? this.description,
        familyFriendly: familyFriendly ?? this.familyFriendly,
        recalledAt: recalledAt ?? this.recalledAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Car &&
        other.id == id &&
        other.make == make &&
        other.description == description &&
        other.familyFriendly == familyFriendly &&
        other.recalledAt == recalledAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([
      id,
      make,
      description,
      familyFriendly,
      recalledAt,
      createdAt,
      updatedAt
    ]);
  }

  Map<String, dynamic> toJson() {
    return CarSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class CarSerializer {
  static Car fromMap(Map map) {
    return new Car(
        id: map['id'] as String,
        make: map['make'] as String,
        description: map['description'] as String,
        familyFriendly: map['family_friendly'] as bool,
        recalledAt: map['recalled_at'] != null
            ? (map['recalled_at'] is DateTime
                ? (map['recalled_at'] as DateTime)
                : DateTime.parse(map['recalled_at'].toString()))
            : null,
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

  static Map<String, dynamic> toMap(_Car model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'make': model.make,
      'description': model.description,
      'family_friendly': model.familyFriendly,
      'recalled_at': model.recalledAt?.toIso8601String(),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class CarFields {
  static const List<String> allFields = const <String>[
    id,
    make,
    description,
    familyFriendly,
    recalledAt,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String make = 'make';

  static const String description = 'description';

  static const String familyFriendly = 'family_friendly';

  static const String recalledAt = 'recalled_at';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
