// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'has_map.dart';

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class HasMapMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('has_maps', (table) {
      table.declare('value', new ColumnType('jsonb'));
      table.declare('list', new ColumnType('jsonb'));
    });
  }

  @override
  down(Schema schema) {
    schema.drop('has_maps');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class HasMapQuery extends Query<HasMap, HasMapQueryWhere> {
  HasMapQuery() {
    _where = new HasMapQueryWhere(this);
  }

  @override
  final HasMapQueryValues values = new HasMapQueryValues();

  HasMapQueryWhere _where;

  @override
  get tableName {
    return 'has_maps';
  }

  @override
  get fields {
    return const ['value', 'list'];
  }

  @override
  HasMapQueryWhere get where {
    return _where;
  }

  @override
  HasMapQueryWhere newWhereClause() {
    return new HasMapQueryWhere(this);
  }

  static HasMap parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new HasMap(
        value: (row[0] as Map<dynamic, dynamic>),
        list: (row[1] as List<dynamic>));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class HasMapQueryWhere extends QueryWhere {
  HasMapQueryWhere(HasMapQuery query)
      : value = new MapSqlExpressionBuilder(query, 'value'),
        list = new ListSqlExpressionBuilder(query, 'list');

  final MapSqlExpressionBuilder value;

  final ListSqlExpressionBuilder list;

  @override
  get expressionBuilders {
    return [value, list];
  }
}

class HasMapQueryValues extends MapQueryValues {
  @override
  get casts {
    return {'list': 'jsonb'};
  }

  Map<dynamic, dynamic> get value {
    return (values['value'] as Map<dynamic, dynamic>);
  }

  set value(Map<dynamic, dynamic> value) => values['value'] = value;
  List<dynamic> get list {
    return (json.decode((values['list'] as String)) as List);
  }

  set list(List<dynamic> value) => values['list'] = json.encode(value);
  void copyFrom(HasMap model) {
    value = model.value;
    list = model.list;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class HasMap implements _HasMap {
  const HasMap({Map<dynamic, dynamic> this.value, List<dynamic> this.list});

  @override
  final Map<dynamic, dynamic> value;

  @override
  final List<dynamic> list;

  HasMap copyWith({Map<dynamic, dynamic> value, List<dynamic> list}) {
    return new HasMap(value: value ?? this.value, list: list ?? this.list);
  }

  bool operator ==(other) {
    return other is _HasMap &&
        const MapEquality<dynamic, dynamic>(
                keys: const DefaultEquality(), values: const DefaultEquality())
            .equals(other.value, value) &&
        const ListEquality<dynamic>(const DefaultEquality())
            .equals(other.list, list);
  }

  @override
  int get hashCode {
    return hashObjects([value, list]);
  }

  Map<String, dynamic> toJson() {
    return HasMapSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class HasMapSerializer {
  static HasMap fromMap(Map map) {
    return new HasMap(
        value: map['value'] is Map
            ? (map['value'] as Map).cast<dynamic, dynamic>()
            : null,
        list: map['list'] is Iterable
            ? (map['list'] as Iterable).cast<dynamic>().toList()
            : null);
  }

  static Map<String, dynamic> toMap(_HasMap model) {
    if (model == null) {
      return null;
    }
    return {'value': model.value, 'list': model.list};
  }
}

abstract class HasMapFields {
  static const List<String> allFields = const <String>[value, list];

  static const String value = 'value';

  static const String list = 'list';
}
