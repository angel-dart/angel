// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.tree;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class TreeQuery extends Query<Tree, TreeQueryWhere> {
  TreeQuery() {}

  @override
  final TreeQueryValues values = new TreeQueryValues();

  @override
  final TreeQueryWhere where = new TreeQueryWhere();

  @override
  get tableName {
    return 'trees';
  }

  @override
  get fields {
    return const ['id', 'rings', 'created_at', 'updated_at'];
  }

  @override
  TreeQueryWhere newWhereClause() {
    return new TreeQueryWhere();
  }

  static Tree parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Tree(
        id: row[0].toString(),
        rings: (row[1] as int),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }

  @override
  insert(executor) {
    return executor.transaction(() async {
      var result = await super.insert(executor);
      where.id.equals(int.parse(result.id));
      result = await getOne(executor);
      result = await fetchLinked(result, executor);
      return result;
    });
  }

  Future<Tree> fetchLinked(Tree model, QueryExecutor executor) async {
    return model.copyWith(
        fruits: await (new FruitQuery()
              ..where.treeId.equals(int.parse(model.id)))
            .get(executor));
  }

  @override
  get(QueryExecutor executor) {
    return executor.transaction(() async {
      var result = await super.get(executor);
      return await Future.wait(result.map((m) => fetchLinked(m, executor)));
    });
  }

  @override
  update(QueryExecutor executor) {
    return executor.transaction(() async {
      var result = await super.update(executor);
      return await Future.wait(result.map((m) => fetchLinked(m, executor)));
    });
  }

  @override
  delete(QueryExecutor executor) {
    return executor.transaction(() async {
      var result = await super.delete(executor);
      return await Future.wait(result.map((m) => fetchLinked(m, executor)));
    });
  }
}

class TreeQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final NumericSqlExpressionBuilder<int> rings =
      new NumericSqlExpressionBuilder<int>('rings');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [id, rings, createdAt, updatedAt];
  }
}

class TreeQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  int get rings {
    return (values['rings'] as int);
  }

  void set rings(int value) => values['rings'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  void set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  void set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Tree model) {
    values.addAll({
      'rings': model.rings,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Tree extends _Tree {
  Tree(
      {this.id, this.rings, List<Fruit> fruits, this.createdAt, this.updatedAt})
      : this.fruits = new List.unmodifiable(fruits ?? []);

  @override
  final String id;

  @override
  final int rings;

  @override
  final List<Fruit> fruits;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Tree copyWith(
      {String id,
      int rings,
      List<Fruit> fruits,
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
        const ListEquality<Fruit>(const DefaultEquality<Fruit>())
            .equals(other.fruits, fruits) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, rings, fruits, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return TreeSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class TreeSerializer {
  static Tree fromMap(Map map) {
    return new Tree(
        id: map['id'] as String,
        rings: map['rings'] as int,
        fruits: map['fruits'] is Iterable
            ? new List.unmodifiable(((map['fruits'] as Iterable)
                    .where((x) => x is Map) as Iterable<Map>)
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

  static Map<String, dynamic> toMap(Tree model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'rings': model.rings,
      'fruits': model.fruits?.map((m) => m.toJson())?.toList(),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class TreeFields {
  static const List<String> allFields = const <String>[
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
