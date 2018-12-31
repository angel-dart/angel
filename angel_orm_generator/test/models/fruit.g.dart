// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.fruit;

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class FruitMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('fruits', (table) {
      table.serial('id')..primaryKey();
      table.integer('tree_id');
      table.varChar('common_name');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('fruits');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class FruitQuery extends Query<Fruit, FruitQueryWhere> {
  FruitQuery() {
    _where = new FruitQueryWhere(this);
  }

  @override
  final FruitQueryValues values = new FruitQueryValues();

  FruitQueryWhere _where;

  @override
  get tableName {
    return 'fruits';
  }

  @override
  get fields {
    return const ['id', 'tree_id', 'common_name', 'created_at', 'updated_at'];
  }

  @override
  FruitQueryWhere get where {
    return _where;
  }

  @override
  FruitQueryWhere newWhereClause() {
    return new FruitQueryWhere(this);
  }

  static Fruit parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Fruit(
        id: row[0].toString(),
        treeId: (row[1] as int),
        commonName: (row[2] as String),
        createdAt: (row[3] as DateTime),
        updatedAt: (row[4] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class FruitQueryWhere extends QueryWhere {
  FruitQueryWhere(FruitQuery query)
      : id = new NumericSqlExpressionBuilder<int>(query, 'id'),
        treeId = new NumericSqlExpressionBuilder<int>(query, 'tree_id'),
        commonName = new StringSqlExpressionBuilder(query, 'common_name'),
        createdAt = new DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = new DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final NumericSqlExpressionBuilder<int> treeId;

  final StringSqlExpressionBuilder commonName;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, treeId, commonName, createdAt, updatedAt];
  }
}

class FruitQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  int get treeId {
    return (values['tree_id'] as int);
  }

  set treeId(int value) => values['tree_id'] = value;
  String get commonName {
    return (values['common_name'] as String);
  }

  set commonName(String value) => values['common_name'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Fruit model) {
    values.addAll({
      'tree_id': model.treeId,
      'common_name': model.commonName,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Fruit extends _Fruit {
  Fruit(
      {this.id, this.treeId, this.commonName, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final int treeId;

  @override
  final String commonName;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Fruit copyWith(
      {String id,
      int treeId,
      String commonName,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Fruit(
        id: id ?? this.id,
        treeId: treeId ?? this.treeId,
        commonName: commonName ?? this.commonName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Fruit &&
        other.id == id &&
        other.treeId == treeId &&
        other.commonName == commonName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, treeId, commonName, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return FruitSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class FruitSerializer {
  static Fruit fromMap(Map map) {
    return new Fruit(
        id: map['id'] as String,
        treeId: map['tree_id'] as int,
        commonName: map['common_name'] as String,
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

  static Map<String, dynamic> toMap(_Fruit model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'tree_id': model.treeId,
      'common_name': model.commonName,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class FruitFields {
  static const List<String> allFields = const <String>[
    id,
    treeId,
    commonName,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String treeId = 'tree_id';

  static const String commonName = 'common_name';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
