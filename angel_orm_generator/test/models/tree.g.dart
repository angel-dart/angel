// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.tree;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class TreeQuery extends Query<Tree, TreeQueryWhere> {
  TreeQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = TreeQueryWhere(this);
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
    return const ['id', 'rings'];
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
    var model = Tree(id: row[0].toString(), rings: (row[1] as int));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class TreeQueryWhere extends QueryWhere {
  TreeQueryWhere(TreeQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        rings = NumericSqlExpressionBuilder<int>(query, 'rings');

  final NumericSqlExpressionBuilder<int> id;

  final NumericSqlExpressionBuilder<int> rings;

  @override
  get expressionBuilders {
    return [id, rings];
  }
}

class TreeQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  int get rings {
    return (values['rings'] as int);
  }

  set rings(int value) => values['rings'] = value;
  void copyFrom(Tree model) {
    rings = model.rings;
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
      List<dynamic> fruits,
      this.createdAt,
      this.updatedAt})
      : this.fruits = new List.unmodifiable(fruits ?? []);

  @override
  final String id;

  @override
  final int rings;

  @override
  final List<dynamic> fruits;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Tree copyWith(
      {String id,
      int rings,
      List<dynamic> fruits,
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
        const ListEquality<dynamic>(const DefaultEquality())
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
            ? (map['fruits'] as Iterable).cast<dynamic>().toList()
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
      'fruits': model.fruits,
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
