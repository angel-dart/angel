// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon.dart';

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class PokemonMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('pokemons', (table) {
      table.serial('id')..primaryKey();
      table.varChar('species');
      table.varChar('name');
      table.integer('level');
      table.integer('type1');
      table.integer('type2');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('pokemons');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class PokemonQuery extends Query<Pokemon, PokemonQueryWhere> {
  PokemonQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = PokemonQueryWhere(this);
  }

  @override
  final PokemonQueryValues values = PokemonQueryValues();

  PokemonQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'pokemons';
  }

  @override
  get fields {
    return const [
      'id',
      'species',
      'name',
      'level',
      'type1',
      'type2',
      'created_at',
      'updated_at'
    ];
  }

  @override
  PokemonQueryWhere get where {
    return _where;
  }

  @override
  PokemonQueryWhere newWhereClause() {
    return PokemonQueryWhere(this);
  }

  static Pokemon parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Pokemon(
        id: row[0].toString(),
        species: (row[1] as String),
        name: (row[2] as String),
        level: (row[3] as int),
        type1: row[4] == null ? null : PokemonType.values[(row[4] as int)],
        type2: row[5] == null ? null : PokemonType.values[(row[5] as int)],
        createdAt: (row[6] as DateTime),
        updatedAt: (row[7] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class PokemonQueryWhere extends QueryWhere {
  PokemonQueryWhere(PokemonQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        species = StringSqlExpressionBuilder(query, 'species'),
        name = StringSqlExpressionBuilder(query, 'name'),
        level = NumericSqlExpressionBuilder<int>(query, 'level'),
        type1 = EnumSqlExpressionBuilder<PokemonType>(
            query, 'type1', (v) => v.index),
        type2 = EnumSqlExpressionBuilder<PokemonType>(
            query, 'type2', (v) => v.index),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final StringSqlExpressionBuilder species;

  final StringSqlExpressionBuilder name;

  final NumericSqlExpressionBuilder<int> level;

  final EnumSqlExpressionBuilder<PokemonType> type1;

  final EnumSqlExpressionBuilder<PokemonType> type2;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, species, name, level, type1, type2, createdAt, updatedAt];
  }
}

class PokemonQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  String get id {
    return (values['id'] as String);
  }

  set id(String value) => values['id'] = value;
  String get species {
    return (values['species'] as String);
  }

  set species(String value) => values['species'] = value;
  String get name {
    return (values['name'] as String);
  }

  set name(String value) => values['name'] = value;
  int get level {
    return (values['level'] as int);
  }

  set level(int value) => values['level'] = value;
  PokemonType get type1 {
    return PokemonType.values[(values['type1'] as int)];
  }

  set type1(PokemonType value) => values['type1'] = value?.index;
  PokemonType get type2 {
    return PokemonType.values[(values['type2'] as int)];
  }

  set type2(PokemonType value) => values['type2'] = value?.index;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Pokemon model) {
    species = model.species;
    name = model.name;
    level = model.level;
    type1 = model.type1;
    type2 = model.type2;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Pokemon extends _Pokemon {
  Pokemon(
      {this.id,
      @required this.species,
      this.name,
      @required this.level,
      @required this.type1,
      this.type2,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final String species;

  @override
  final String name;

  @override
  final int level;

  @override
  final PokemonType type1;

  @override
  final PokemonType type2;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Pokemon copyWith(
      {String id,
      String species,
      String name,
      int level,
      PokemonType type1,
      PokemonType type2,
      DateTime createdAt,
      DateTime updatedAt}) {
    return Pokemon(
        id: id ?? this.id,
        species: species ?? this.species,
        name: name ?? this.name,
        level: level ?? this.level,
        type1: type1 ?? this.type1,
        type2: type2 ?? this.type2,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Pokemon &&
        other.id == id &&
        other.species == species &&
        other.name == name &&
        other.level == level &&
        other.type1 == type1 &&
        other.type2 == type2 &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects(
        [id, species, name, level, type1, type2, createdAt, updatedAt]);
  }

  @override
  String toString() {
    return "Pokemon(id=$id, species=$species, name=$name, level=$level, type1=$type1, type2=$type2, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return PokemonSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const PokemonSerializer pokemonSerializer = PokemonSerializer();

class PokemonEncoder extends Converter<Pokemon, Map> {
  const PokemonEncoder();

  @override
  Map convert(Pokemon model) => PokemonSerializer.toMap(model);
}

class PokemonDecoder extends Converter<Map, Pokemon> {
  const PokemonDecoder();

  @override
  Pokemon convert(Map map) => PokemonSerializer.fromMap(map);
}

class PokemonSerializer extends Codec<Pokemon, Map> {
  const PokemonSerializer();

  @override
  get encoder => const PokemonEncoder();
  @override
  get decoder => const PokemonDecoder();
  static Pokemon fromMap(Map map) {
    if (map['species'] == null) {
      throw FormatException("Missing required field 'species' on Pokemon.");
    }

    if (map['level'] == null) {
      throw FormatException("Missing required field 'level' on Pokemon.");
    }

    if (map['type1'] == null) {
      throw FormatException("Missing required field 'type1' on Pokemon.");
    }

    return Pokemon(
        id: map['id'] as String,
        species: map['species'] as String,
        name: map['name'] as String,
        level: map['level'] as int,
        type1: map['type1'] is PokemonType
            ? (map['type1'] as PokemonType)
            : (map['type1'] is int
                ? PokemonType.values[map['type1'] as int]
                : null),
        type2: map['type2'] is PokemonType
            ? (map['type2'] as PokemonType)
            : (map['type2'] is int
                ? PokemonType.values[map['type2'] as int]
                : null),
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

  static Map<String, dynamic> toMap(_Pokemon model) {
    if (model == null) {
      return null;
    }
    if (model.species == null) {
      throw FormatException("Missing required field 'species' on Pokemon.");
    }

    if (model.level == null) {
      throw FormatException("Missing required field 'level' on Pokemon.");
    }

    if (model.type1 == null) {
      throw FormatException("Missing required field 'type1' on Pokemon.");
    }

    return {
      'id': model.id,
      'species': model.species,
      'name': model.name,
      'level': model.level,
      'type1':
          model.type1 == null ? null : PokemonType.values.indexOf(model.type1),
      'type2':
          model.type2 == null ? null : PokemonType.values.indexOf(model.type2),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class PokemonFields {
  static const List<String> allFields = <String>[
    id,
    species,
    name,
    level,
    type1,
    type2,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String species = 'species';

  static const String name = 'name';

  static const String level = 'level';

  static const String type1 = 'type1';

  static const String type2 = 'type2';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
