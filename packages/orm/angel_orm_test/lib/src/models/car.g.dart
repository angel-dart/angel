// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.car;

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class CarMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('cars', (table) {
      table.serial('id')..primaryKey();
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.varChar('make');
      table.varChar('description');
      table.boolean('family_friendly');
      table.timeStamp('recalled_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('cars');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class CarQuery extends Query<Car, CarQueryWhere> {
  CarQuery({Query parent, Set<String> trampoline}) : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = CarQueryWhere(this);
  }

  @override
  final CarQueryValues values = CarQueryValues();

  CarQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'cars';
  }

  @override
  get fields {
    return const [
      'id',
      'created_at',
      'updated_at',
      'make',
      'description',
      'family_friendly',
      'recalled_at'
    ];
  }

  @override
  CarQueryWhere get where {
    return _where;
  }

  @override
  CarQueryWhere newWhereClause() {
    return CarQueryWhere(this);
  }

  static Car parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Car(
        id: row[0].toString(),
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime),
        make: (row[3] as String),
        description: (row[4] as String),
        familyFriendly: (row[5] as bool),
        recalledAt: (row[6] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class CarQueryWhere extends QueryWhere {
  CarQueryWhere(CarQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at'),
        make = StringSqlExpressionBuilder(query, 'make'),
        description = StringSqlExpressionBuilder(query, 'description'),
        familyFriendly = BooleanSqlExpressionBuilder(query, 'family_friendly'),
        recalledAt = DateTimeSqlExpressionBuilder(query, 'recalled_at');

  final NumericSqlExpressionBuilder<int> id;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  final StringSqlExpressionBuilder make;

  final StringSqlExpressionBuilder description;

  final BooleanSqlExpressionBuilder familyFriendly;

  final DateTimeSqlExpressionBuilder recalledAt;

  @override
  get expressionBuilders {
    return [
      id,
      createdAt,
      updatedAt,
      make,
      description,
      familyFriendly,
      recalledAt
    ];
  }
}

class CarQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  String get id {
    return (values['id'] as String);
  }

  set id(String value) => values['id'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  String get make {
    return (values['make'] as String);
  }

  set make(String value) => values['make'] = value;
  String get description {
    return (values['description'] as String);
  }

  set description(String value) => values['description'] = value;
  bool get familyFriendly {
    return (values['family_friendly'] as bool);
  }

  set familyFriendly(bool value) => values['family_friendly'] = value;
  DateTime get recalledAt {
    return (values['recalled_at'] as DateTime);
  }

  set recalledAt(DateTime value) => values['recalled_at'] = value;
  void copyFrom(Car model) {
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    make = model.make;
    description = model.description;
    familyFriendly = model.familyFriendly;
    recalledAt = model.recalledAt;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Car extends _Car {
  Car(
      {this.id,
      this.createdAt,
      this.updatedAt,
      this.make,
      this.description,
      this.familyFriendly,
      this.recalledAt});

  /// A unique identifier corresponding to this item.
  @override
  String id;

  /// The time at which this item was created.
  @override
  DateTime createdAt;

  /// The last time at which this item was updated.
  @override
  DateTime updatedAt;

  @override
  String make;

  @override
  String description;

  @override
  bool familyFriendly;

  @override
  DateTime recalledAt;

  Car copyWith(
      {String id,
      DateTime createdAt,
      DateTime updatedAt,
      String make,
      String description,
      bool familyFriendly,
      DateTime recalledAt}) {
    return Car(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        make: make ?? this.make,
        description: description ?? this.description,
        familyFriendly: familyFriendly ?? this.familyFriendly,
        recalledAt: recalledAt ?? this.recalledAt);
  }

  bool operator ==(other) {
    return other is _Car &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.make == make &&
        other.description == description &&
        other.familyFriendly == familyFriendly &&
        other.recalledAt == recalledAt;
  }

  @override
  int get hashCode {
    return hashObjects([
      id,
      createdAt,
      updatedAt,
      make,
      description,
      familyFriendly,
      recalledAt
    ]);
  }

  @override
  String toString() {
    return "Car(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, make=$make, description=$description, familyFriendly=$familyFriendly, recalledAt=$recalledAt)";
  }

  Map<String, dynamic> toJson() {
    return CarSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const CarSerializer carSerializer = CarSerializer();

class CarEncoder extends Converter<Car, Map> {
  const CarEncoder();

  @override
  Map convert(Car model) => CarSerializer.toMap(model);
}

class CarDecoder extends Converter<Map, Car> {
  const CarDecoder();

  @override
  Car convert(Map map) => CarSerializer.fromMap(map);
}

class CarSerializer extends Codec<Car, Map> {
  const CarSerializer();

  @override
  get encoder => const CarEncoder();
  @override
  get decoder => const CarDecoder();
  static Car fromMap(Map map) {
    return Car(
        id: map['id'] as String,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null,
        make: map['make'] as String,
        description: map['description'] as String,
        familyFriendly: map['family_friendly'] as bool,
        recalledAt: map['recalled_at'] != null
            ? (map['recalled_at'] is DateTime
                ? (map['recalled_at'] as DateTime)
                : DateTime.parse(map['recalled_at'].toString()))
            : null);
  }

  static Map<String, dynamic> toMap(_Car model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'make': model.make,
      'description': model.description,
      'family_friendly': model.familyFriendly,
      'recalled_at': model.recalledAt?.toIso8601String()
    };
  }
}

abstract class CarFields {
  static const List<String> allFields = <String>[
    id,
    createdAt,
    updatedAt,
    make,
    description,
    familyFriendly,
    recalledAt
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String make = 'make';

  static const String description = 'description';

  static const String familyFriendly = 'family_friendly';

  static const String recalledAt = 'recalled_at';
}
