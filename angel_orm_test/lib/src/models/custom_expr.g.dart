// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_expr.dart';

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class NumbersMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('numbers', (table) {
      table.serial('id')..primaryKey();
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('numbers');
  }
}

class AlphabetMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('alphabets', (table) {
      table.serial('id')..primaryKey();
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.varChar('value');
      table
          .declare('numbers_id', ColumnType('serial'))
          .references('numbers', 'id');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('alphabets');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class NumbersQuery extends Query<Numbers, NumbersQueryWhere> {
  NumbersQuery({Query parent, Set<String> trampoline}) : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    expressions['two'] = 'SELECT 2';
    _where = NumbersQueryWhere(this);
  }

  @override
  final NumbersQueryValues values = NumbersQueryValues();

  NumbersQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'numbers';
  }

  @override
  get fields {
    return const ['id', 'created_at', 'updated_at', 'two'];
  }

  @override
  NumbersQueryWhere get where {
    return _where;
  }

  @override
  NumbersQueryWhere newWhereClause() {
    return NumbersQueryWhere(this);
  }

  static Numbers parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Numbers(
        id: row[0].toString(),
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime),
        two: (row[3] as int));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class NumbersQueryWhere extends QueryWhere {
  NumbersQueryWhere(NumbersQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, createdAt, updatedAt];
  }
}

class NumbersQueryValues extends MapQueryValues {
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
  void copyFrom(Numbers model) {
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

class AlphabetQuery extends Query<Alphabet, AlphabetQueryWhere> {
  AlphabetQuery({Query parent, Set<String> trampoline})
      : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = AlphabetQueryWhere(this);
    leftJoin(_numbers = NumbersQuery(trampoline: trampoline, parent: this),
        'numbers_id', 'id',
        additionalFields: const ['id', 'created_at', 'updated_at', 'two'],
        trampoline: trampoline);
  }

  @override
  final AlphabetQueryValues values = AlphabetQueryValues();

  AlphabetQueryWhere _where;

  NumbersQuery _numbers;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'alphabets';
  }

  @override
  get fields {
    return const ['id', 'created_at', 'updated_at', 'value', 'numbers_id'];
  }

  @override
  AlphabetQueryWhere get where {
    return _where;
  }

  @override
  AlphabetQueryWhere newWhereClause() {
    return AlphabetQueryWhere(this);
  }

  static Alphabet parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Alphabet(
        id: row[0].toString(),
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime),
        value: (row[3] as String));
    if (row.length > 5) {
      model = model.copyWith(
          numbers: NumbersQuery.parseRow(row.skip(5).take(4).toList()));
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }

  NumbersQuery get numbers {
    return _numbers;
  }
}

class AlphabetQueryWhere extends QueryWhere {
  AlphabetQueryWhere(AlphabetQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at'),
        value = StringSqlExpressionBuilder(query, 'value'),
        numbersId = NumericSqlExpressionBuilder<int>(query, 'numbers_id');

  final NumericSqlExpressionBuilder<int> id;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  final StringSqlExpressionBuilder value;

  final NumericSqlExpressionBuilder<int> numbersId;

  @override
  get expressionBuilders {
    return [id, createdAt, updatedAt, value, numbersId];
  }
}

class AlphabetQueryValues extends MapQueryValues {
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
  String get value {
    return (values['value'] as String);
  }

  set value(String value) => values['value'] = value;
  int get numbersId {
    return (values['numbers_id'] as int);
  }

  set numbersId(int value) => values['numbers_id'] = value;
  void copyFrom(Alphabet model) {
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    value = model.value;
    if (model.numbers != null) {
      values['numbers_id'] = model.numbers.id;
    }
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Numbers extends _Numbers {
  Numbers({this.id, this.createdAt, this.updatedAt, this.two});

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
  int two;

  Numbers copyWith(
      {String id, DateTime createdAt, DateTime updatedAt, int two}) {
    return Numbers(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        two: two ?? this.two);
  }

  bool operator ==(other) {
    return other is _Numbers &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.two == two;
  }

  @override
  int get hashCode {
    return hashObjects([id, createdAt, updatedAt, two]);
  }

  @override
  String toString() {
    return "Numbers(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, two=$two)";
  }

  Map<String, dynamic> toJson() {
    return NumbersSerializer.toMap(this);
  }
}

@generatedSerializable
class Alphabet extends _Alphabet {
  Alphabet({this.id, this.createdAt, this.updatedAt, this.value, this.numbers});

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
  String value;

  @override
  _Numbers numbers;

  Alphabet copyWith(
      {String id,
      DateTime createdAt,
      DateTime updatedAt,
      String value,
      _Numbers numbers}) {
    return Alphabet(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        value: value ?? this.value,
        numbers: numbers ?? this.numbers);
  }

  bool operator ==(other) {
    return other is _Alphabet &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.value == value &&
        other.numbers == numbers;
  }

  @override
  int get hashCode {
    return hashObjects([id, createdAt, updatedAt, value, numbers]);
  }

  @override
  String toString() {
    return "Alphabet(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, value=$value, numbers=$numbers)";
  }

  Map<String, dynamic> toJson() {
    return AlphabetSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const NumbersSerializer numbersSerializer = NumbersSerializer();

class NumbersEncoder extends Converter<Numbers, Map> {
  const NumbersEncoder();

  @override
  Map convert(Numbers model) => NumbersSerializer.toMap(model);
}

class NumbersDecoder extends Converter<Map, Numbers> {
  const NumbersDecoder();

  @override
  Numbers convert(Map map) => NumbersSerializer.fromMap(map);
}

class NumbersSerializer extends Codec<Numbers, Map> {
  const NumbersSerializer();

  @override
  get encoder => const NumbersEncoder();
  @override
  get decoder => const NumbersDecoder();
  static Numbers fromMap(Map map) {
    return Numbers(
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
        two: map['two'] as int);
  }

  static Map<String, dynamic> toMap(_Numbers model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'two': model.two
    };
  }
}

abstract class NumbersFields {
  static const List<String> allFields = <String>[id, createdAt, updatedAt, two];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String two = 'two';
}

const AlphabetSerializer alphabetSerializer = AlphabetSerializer();

class AlphabetEncoder extends Converter<Alphabet, Map> {
  const AlphabetEncoder();

  @override
  Map convert(Alphabet model) => AlphabetSerializer.toMap(model);
}

class AlphabetDecoder extends Converter<Map, Alphabet> {
  const AlphabetDecoder();

  @override
  Alphabet convert(Map map) => AlphabetSerializer.fromMap(map);
}

class AlphabetSerializer extends Codec<Alphabet, Map> {
  const AlphabetSerializer();

  @override
  get encoder => const AlphabetEncoder();
  @override
  get decoder => const AlphabetDecoder();
  static Alphabet fromMap(Map map) {
    return Alphabet(
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
        value: map['value'] as String,
        numbers: map['numbers'] != null
            ? NumbersSerializer.fromMap(map['numbers'] as Map)
            : null);
  }

  static Map<String, dynamic> toMap(_Alphabet model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'value': model.value,
      'numbers': NumbersSerializer.toMap(model.numbers)
    };
  }
}

abstract class AlphabetFields {
  static const List<String> allFields = <String>[
    id,
    createdAt,
    updatedAt,
    value,
    numbers
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String value = 'value';

  static const String numbers = 'numbers';
}
