// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.car;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class CarQuery extends Query<Car, CarQueryWhere> {
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
      'familyFriendly',
      'recalledAt',
      'createdAt',
      'updatedAt'
    ];
  }

  @override
  deserialize(List row) {
    return new Car(
        id: (row[0] as String),
        make: (row[0] as String),
        description: (row[0] as String),
        familyFriendly: (row[0] as bool),
        recalledAt: (row[0] as DateTime),
        createdAt: (row[0] as DateTime),
        updatedAt: (row[0] as DateTime));
  }
}

class CarQueryWhere extends QueryWhere {
  final StringSqlExpressionBuilder id = new StringSqlExpressionBuilder('id');

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
