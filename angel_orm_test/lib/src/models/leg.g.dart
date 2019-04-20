// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.leg;

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class LegMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('legs', (table) {
      table.serial('id')..primaryKey();
      table.varChar('name');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('legs', cascade: true);
  }
}

class FootMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('feet', (table) {
      table.serial('id')..primaryKey();
      table.integer('leg_id');
      table.declare('n_toes', ColumnType('decimal'));
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('feet');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class LegQuery extends Query<Leg, LegQueryWhere> {
  LegQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = LegQueryWhere(this);
    leftJoin('feet', 'id', 'leg_id',
        additionalFields: const [
          'id',
          'leg_id',
          'n_toes',
          'created_at',
          'updated_at'
        ],
        trampoline: trampoline);
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
    return const ['id', 'name', 'created_at', 'updated_at'];
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
    var model = Leg(
        id: row[0].toString(),
        name: (row[1] as String),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
    if (row.length > 4) {
      model = model.copyWith(
          foot: FootQuery.parseRow(row.skip(4).take(5).toList()));
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class LegQueryWhere extends QueryWhere {
  LegQueryWhere(LegQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        name = StringSqlExpressionBuilder(query, 'name'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final StringSqlExpressionBuilder name;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, name, createdAt, updatedAt];
  }
}

class LegQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  String get id {
    return (values['id'] as String);
  }

  set id(String value) => values['id'] = value;
  String get name {
    return (values['name'] as String);
  }

  set name(String value) => values['name'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Leg model) {
    name = model.name;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

class FootQuery extends Query<Foot, FootQueryWhere> {
  FootQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = FootQueryWhere(this);
  }

  @override
  final FootQueryValues values = FootQueryValues();

  FootQueryWhere _where;

  @override
  get casts {
    return {'n_toes': 'text'};
  }

  @override
  get tableName {
    return 'feet';
  }

  @override
  get fields {
    return const ['id', 'leg_id', 'n_toes', 'created_at', 'updated_at'];
  }

  @override
  FootQueryWhere get where {
    return _where;
  }

  @override
  FootQueryWhere newWhereClause() {
    return FootQueryWhere(this);
  }

  static Foot parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Foot(
        id: row[0].toString(),
        legId: (row[1] as int),
        nToes: double.tryParse(row[2].toString()),
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
  FootQueryWhere(FootQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        legId = NumericSqlExpressionBuilder<int>(query, 'leg_id'),
        nToes = NumericSqlExpressionBuilder<double>(query, 'n_toes'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final NumericSqlExpressionBuilder<int> legId;

  final NumericSqlExpressionBuilder<double> nToes;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, legId, nToes, createdAt, updatedAt];
  }
}

class FootQueryValues extends MapQueryValues {
  @override
  get casts {
    return {'n_toes': 'decimal'};
  }

  String get id {
    return (values['id'] as String);
  }

  set id(String value) => values['id'] = value;
  int get legId {
    return (values['leg_id'] as int);
  }

  set legId(int value) => values['leg_id'] = value;
  double get nToes {
    return double.tryParse((values['n_toes'] as String));
  }

  set nToes(double value) => values['n_toes'] = value.toString();
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Foot model) {
    legId = model.legId;
    nToes = model.nToes;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
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
  final _Foot foot;

  @override
  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Leg copyWith(
      {String id,
      _Foot foot,
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

  @override
  String toString() {
    return "Leg(id=$id, foot=$foot, name=$name, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return LegSerializer.toMap(this);
  }
}

@generatedSerializable
class Foot extends _Foot {
  Foot({this.id, this.legId, this.nToes, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final int legId;

  @override
  final double nToes;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Foot copyWith(
      {String id,
      int legId,
      double nToes,
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

  @override
  String toString() {
    return "Foot(id=$id, legId=$legId, nToes=$nToes, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return FootSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const LegSerializer legSerializer = const LegSerializer();

class LegEncoder extends Converter<Leg, Map> {
  const LegEncoder();

  @override
  Map convert(Leg model) => LegSerializer.toMap(model);
}

class LegDecoder extends Converter<Map, Leg> {
  const LegDecoder();

  @override
  Leg convert(Map map) => LegSerializer.fromMap(map);
}

class LegSerializer extends Codec<Leg, Map> {
  const LegSerializer();

  @override
  get encoder => const LegEncoder();
  @override
  get decoder => const LegDecoder();
  static Leg fromMap(Map map) {
    return new Leg(
        id: map['id'] as String,
        foot: map['foot'] != null
            ? FootSerializer.fromMap(map['foot'] as Map)
            : null,
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
      'foot': FootSerializer.toMap(model.foot),
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

const FootSerializer footSerializer = const FootSerializer();

class FootEncoder extends Converter<Foot, Map> {
  const FootEncoder();

  @override
  Map convert(Foot model) => FootSerializer.toMap(model);
}

class FootDecoder extends Converter<Map, Foot> {
  const FootDecoder();

  @override
  Foot convert(Map map) => FootSerializer.fromMap(map);
}

class FootSerializer extends Codec<Foot, Map> {
  const FootSerializer();

  @override
  get encoder => const FootEncoder();
  @override
  get decoder => const FootDecoder();
  static Foot fromMap(Map map) {
    return new Foot(
        id: map['id'] as String,
        legId: map['leg_id'] as int,
        nToes: map['n_toes'] as double,
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
  static const List<String> allFields = <String>[
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
