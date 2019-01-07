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
      table.declare('rings', new ColumnType('smallint'));
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('trees');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class TreeQuery extends Query<Tree, TreeQueryWhere> {
  TreeQuery() {
    _where = new TreeQueryWhere(this);
    leftJoin('(' + new FruitQuery().compile() + ')', 'id', 'tree_id',
        additionalFields: const [
          'tree_id',
          'common_name',
          'created_at',
          'updated_at'
        ]);
  }

  @override
  final TreeQueryValues values = new TreeQueryValues();

  TreeQueryWhere _where;

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
    return new TreeQueryWhere(this);
  }

  static Tree parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Tree(
        id: row[0].toString(),
        rings: (row[1] as int),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
    if (row.length > 4) {
      model = model.copyWith(
          fruits: [FruitQuery.parseRow(row.skip(4).toList())]
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
                fruits: List<Fruit>.from(l.fruits ?? [])
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
                fruits: List<Fruit>.from(l.fruits ?? [])
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
                fruits: List<Fruit>.from(l.fruits ?? [])
                  ..addAll(model.fruits ?? []));
        }
      });
    });
  }
}

class TreeQueryWhere extends QueryWhere {
  TreeQueryWhere(TreeQuery query)
      : id = new NumericSqlExpressionBuilder<int>(query, 'id'),
        rings = new NumericSqlExpressionBuilder<int>(query, 'rings'),
        createdAt = new DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = new DateTimeSqlExpressionBuilder(query, 'updated_at');

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
  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
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
