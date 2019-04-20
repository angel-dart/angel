// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.tree;

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class TreeMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('trees', (table) {
      table.serial('id')..primaryKey();
      table.integer('rings');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('trees', cascade: true);
  }
}

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

class TreeQuery extends Query<Tree, TreeQueryWhere> {
  TreeQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = TreeQueryWhere(this);
    leftJoin(FruitQuery(trampoline: trampoline), 'id', 'tree_id',
        additionalFields: const [
          'id',
          'tree_id',
          'common_name',
          'created_at',
          'updated_at'
        ],
        trampoline: trampoline);
  }

  @override
  final TreeQueryValues values = TreeQueryValues();

  TreeQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'trees';
  }

  @override
  get fields {
    return const ['id', 'rings', 'created_at', 'updated_at'];
  }

  @override
  TreeQueryWhere get where {
    return _where;
  }

  @override
  TreeQueryWhere newWhereClause() {
    return TreeQueryWhere(this);
  }

  static Tree parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Tree(
        id: row[0].toString(),
        rings: (row[1] as int),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
    if (row.length > 4) {
      model = model.copyWith(
          fruits: [FruitQuery.parseRow(row.skip(4).take(5).toList())]
              .where((x) => x != null)
              .toList());
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }

  @override
  get(QueryExecutor executor) {
    return super.get(executor).then((result) {
      return result.fold<List<Tree>>([], (out, model) {
        var idx = out.indexWhere((m) => m.id == model.id);

        if (idx == -1) {
          return out..add(model);
        } else {
          var l = out[idx];
          return out
            ..[idx] = l.copyWith(
                fruits: List<_Fruit>.from(l.fruits ?? [])
                  ..addAll(model.fruits ?? []));
        }
      });
    });
  }

  @override
  update(QueryExecutor executor) {
    return super.update(executor).then((result) {
      return result.fold<List<Tree>>([], (out, model) {
        var idx = out.indexWhere((m) => m.id == model.id);

        if (idx == -1) {
          return out..add(model);
        } else {
          var l = out[idx];
          return out
            ..[idx] = l.copyWith(
                fruits: List<_Fruit>.from(l.fruits ?? [])
                  ..addAll(model.fruits ?? []));
        }
      });
    });
  }

  @override
  delete(QueryExecutor executor) {
    return super.delete(executor).then((result) {
      return result.fold<List<Tree>>([], (out, model) {
        var idx = out.indexWhere((m) => m.id == model.id);

        if (idx == -1) {
          return out..add(model);
        } else {
          var l = out[idx];
          return out
            ..[idx] = l.copyWith(
                fruits: List<_Fruit>.from(l.fruits ?? [])
                  ..addAll(model.fruits ?? []));
        }
      });
    });
  }
}

class TreeQueryWhere extends QueryWhere {
  TreeQueryWhere(TreeQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        rings = NumericSqlExpressionBuilder<int>(query, 'rings'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final NumericSqlExpressionBuilder<int> rings;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, rings, createdAt, updatedAt];
  }
}

class TreeQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  String get id {
    return (values['id'] as String);
  }

  set id(String value) => values['id'] = value;
  int get rings {
    return (values['rings'] as int);
  }

  set rings(int value) => values['rings'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Tree model) {
    rings = model.rings;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

class FruitQuery extends Query<Fruit, FruitQueryWhere> {
  FruitQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = FruitQueryWhere(this);
  }

  @override
  final FruitQueryValues values = FruitQueryValues();

  FruitQueryWhere _where;

  @override
  get casts {
    return {};
  }

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
    return FruitQueryWhere(this);
  }

  static Fruit parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Fruit(
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
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        treeId = NumericSqlExpressionBuilder<int>(query, 'tree_id'),
        commonName = StringSqlExpressionBuilder(query, 'common_name'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

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
  @override
  get casts {
    return {};
  }

  String get id {
    return (values['id'] as String);
  }

  set id(String value) => values['id'] = value;
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
    treeId = model.treeId;
    commonName = model.commonName;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Tree extends _Tree {
  Tree(
      {this.id,
      this.rings,
      List<_Fruit> fruits,
      this.createdAt,
      this.updatedAt})
      : this.fruits = new List.unmodifiable(fruits ?? []);

  @override
  final String id;

  @override
  final int rings;

  @override
  final List<_Fruit> fruits;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Tree copyWith(
      {String id,
      int rings,
      List<_Fruit> fruits,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Tree(
        id: id ?? this.id,
        rings: rings ?? this.rings,
        fruits: fruits ?? this.fruits,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Tree &&
        other.id == id &&
        other.rings == rings &&
        const ListEquality<_Fruit>(const DefaultEquality<_Fruit>())
            .equals(other.fruits, fruits) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, rings, fruits, createdAt, updatedAt]);
  }

  @override
  String toString() {
    return "Tree(id=$id, rings=$rings, fruits=$fruits, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return TreeSerializer.toMap(this);
  }
}

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

  @override
  String toString() {
    return "Fruit(id=$id, treeId=$treeId, commonName=$commonName, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return FruitSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const TreeSerializer treeSerializer = const TreeSerializer();

class TreeEncoder extends Converter<Tree, Map> {
  const TreeEncoder();

  @override
  Map convert(Tree model) => TreeSerializer.toMap(model);
}

class TreeDecoder extends Converter<Map, Tree> {
  const TreeDecoder();

  @override
  Tree convert(Map map) => TreeSerializer.fromMap(map);
}

class TreeSerializer extends Codec<Tree, Map> {
  const TreeSerializer();

  @override
  get encoder => const TreeEncoder();
  @override
  get decoder => const TreeDecoder();
  static Tree fromMap(Map map) {
    return new Tree(
        id: map['id'] as String,
        rings: map['rings'] as int,
        fruits: map['fruits'] is Iterable
            ? new List.unmodifiable(
                ((map['fruits'] as Iterable).where((x) => x is Map))
                    .cast<Map>()
                    .map(FruitSerializer.fromMap))
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

  static Map<String, dynamic> toMap(_Tree model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'rings': model.rings,
      'fruits': model.fruits?.map((m) => FruitSerializer.toMap(m))?.toList(),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class TreeFields {
  static const List<String> allFields = <String>[
    id,
    rings,
    fruits,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String rings = 'rings';

  static const String fruits = 'fruits';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

const FruitSerializer fruitSerializer = const FruitSerializer();

class FruitEncoder extends Converter<Fruit, Map> {
  const FruitEncoder();

  @override
  Map convert(Fruit model) => FruitSerializer.toMap(model);
}

class FruitDecoder extends Converter<Map, Fruit> {
  const FruitDecoder();

  @override
  Fruit convert(Map map) => FruitSerializer.fromMap(map);
}

class FruitSerializer extends Codec<Fruit, Map> {
  const FruitSerializer();

  @override
  get encoder => const FruitEncoder();
  @override
  get decoder => const FruitDecoder();
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
  static const List<String> allFields = <String>[
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
