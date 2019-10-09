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
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.varChar('name');
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
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.integer('leg_id');
      table.declare('n_toes', ColumnType('decimal'));
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
  LegQuery({Query parent, Set<String> trampoline}) : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = LegQueryWhere(this);
    leftJoin(
        _foot = FootQuery(trampoline: trampoline, parent: this), 'id', 'leg_id',
        additionalFields: const [
          'id',
          'created_at',
          'updated_at',
          'leg_id',
          'n_toes'
        ],
        trampoline: trampoline);
  }

  @override
  final LegQueryValues values = LegQueryValues();

  LegQueryWhere _where;

  FootQuery _foot;

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
    return const ['id', 'created_at', 'updated_at', 'name'];
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
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime),
        name: (row[3] as String));
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

  FootQuery get foot {
    return _foot;
  }
}

class LegQueryWhere extends QueryWhere {
  LegQueryWhere(LegQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at'),
        name = StringSqlExpressionBuilder(query, 'name');

  final NumericSqlExpressionBuilder<int> id;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  final StringSqlExpressionBuilder name;

  @override
  get expressionBuilders {
    return [id, createdAt, updatedAt, name];
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
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  String get name {
    return (values['name'] as String);
  }

  set name(String value) => values['name'] = value;
  void copyFrom(Leg model) {
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    name = model.name;
  }
}

class FootQuery extends Query<Foot, FootQueryWhere> {
  FootQuery({Query parent, Set<String> trampoline}) : super(parent: parent) {
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
    return const ['id', 'created_at', 'updated_at', 'leg_id', 'n_toes'];
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
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime),
        legId: (row[3] as int),
        nToes: double.tryParse(row[4].toString()));
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
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at'),
        legId = NumericSqlExpressionBuilder<int>(query, 'leg_id'),
        nToes = NumericSqlExpressionBuilder<double>(query, 'n_toes');

  final NumericSqlExpressionBuilder<int> id;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  final NumericSqlExpressionBuilder<int> legId;

  final NumericSqlExpressionBuilder<double> nToes;

  @override
  get expressionBuilders {
    return [id, createdAt, updatedAt, legId, nToes];
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
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  int get legId {
    return (values['leg_id'] as int);
  }

  set legId(int value) => values['leg_id'] = value;
  double get nToes {
    return double.tryParse((values['n_toes'] as String));
  }

  set nToes(double value) => values['n_toes'] = value.toString();
  void copyFrom(Foot model) {
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    legId = model.legId;
    nToes = model.nToes;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Leg extends _Leg {
  Leg({this.id, this.createdAt, this.updatedAt, this.foot, this.name});

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
  _Foot foot;

  @override
  String name;

  Leg copyWith(
      {String id,
      DateTime createdAt,
      DateTime updatedAt,
      _Foot foot,
      String name}) {
    return Leg(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        foot: foot ?? this.foot,
        name: name ?? this.name);
  }

  bool operator ==(other) {
    return other is _Leg &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.foot == foot &&
        other.name == name;
  }

  @override
  int get hashCode {
    return hashObjects([id, createdAt, updatedAt, foot, name]);
  }

  @override
  String toString() {
    return "Leg(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, foot=$foot, name=$name)";
  }

  Map<String, dynamic> toJson() {
    return LegSerializer.toMap(this);
  }
}

@generatedSerializable
class Foot extends _Foot {
  Foot({this.id, this.createdAt, this.updatedAt, this.legId, this.nToes});

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
  int legId;

  @override
  double nToes;

  Foot copyWith(
      {String id,
      DateTime createdAt,
      DateTime updatedAt,
      int legId,
      double nToes}) {
    return Foot(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        legId: legId ?? this.legId,
        nToes: nToes ?? this.nToes);
  }

  bool operator ==(other) {
    return other is _Foot &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.legId == legId &&
        other.nToes == nToes;
  }

  @override
  int get hashCode {
    return hashObjects([id, createdAt, updatedAt, legId, nToes]);
  }

  @override
  String toString() {
    return "Foot(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, legId=$legId, nToes=$nToes)";
  }

  Map<String, dynamic> toJson() {
    return FootSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const LegSerializer legSerializer = LegSerializer();

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
    return Leg(
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
        foot: map['foot'] != null
            ? FootSerializer.fromMap(map['foot'] as Map)
            : null,
        name: map['name'] as String);
  }

  static Map<String, dynamic> toMap(_Leg model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'foot': FootSerializer.toMap(model.foot),
      'name': model.name
    };
  }
}

abstract class LegFields {
  static const List<String> allFields = <String>[
    id,
    createdAt,
    updatedAt,
    foot,
    name
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String foot = 'foot';

  static const String name = 'name';
}

const FootSerializer footSerializer = FootSerializer();

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
    return Foot(
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
        legId: map['leg_id'] as int,
        nToes: map['n_toes'] as double);
  }

  static Map<String, dynamic> toMap(_Foot model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'leg_id': model.legId,
      'n_toes': model.nToes
    };
  }
}

abstract class FootFields {
  static const List<String> allFields = <String>[
    id,
    createdAt,
    updatedAt,
    legId,
    nToes
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String legId = 'leg_id';

  static const String nToes = 'n_toes';
}
