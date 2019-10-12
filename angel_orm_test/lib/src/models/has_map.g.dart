// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'has_map.dart';

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class HasMapMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('has_maps', (table) {
      table.declare('value', ColumnType('jsonb'));
      table.declare('list', ColumnType('jsonb'));
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
  HasMapQuery({Query parent, Set<String> trampoline}) : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = HasMapQueryWhere(this);
  }

  @override
  final HasMapQueryValues values = HasMapQueryValues();

  HasMapQueryWhere _where;

  @override
  get casts {
    return {};
  }

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
    return HasMapQueryWhere(this);
  }

  static HasMap parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = HasMap(
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
      : value = MapSqlExpressionBuilder(query, 'value'),
        list = ListSqlExpressionBuilder(query, 'list');

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
  const HasMap({this.value, this.list});

  @override
  final Map<dynamic, dynamic> value;

  @override
  final List<dynamic> list;

  HasMap copyWith({Map<dynamic, dynamic> value, List<dynamic> list}) {
    return HasMap(value: value ?? this.value, list: list ?? this.list);
  }

  bool operator ==(other) {
    return other is _HasMap &&
        MapEquality<dynamic, dynamic>(
                keys: DefaultEquality(), values: DefaultEquality())
            .equals(other.value, value) &&
        ListEquality<dynamic>(DefaultEquality()).equals(other.list, list);
  }

  @override
  int get hashCode {
    return hashObjects([value, list]);
  }

  @override
  String toString() {
    return "HasMap(value=$value, list=$list)";
  }

  Map<String, dynamic> toJson() {
    return HasMapSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const HasMapSerializer hasMapSerializer = HasMapSerializer();

class HasMapEncoder extends Converter<HasMap, Map> {
  const HasMapEncoder();

  @override
  Map convert(HasMap model) => HasMapSerializer.toMap(model);
}

class HasMapDecoder extends Converter<Map, HasMap> {
  const HasMapDecoder();

  @override
  HasMap convert(Map map) => HasMapSerializer.fromMap(map);
}

class HasMapSerializer extends Codec<HasMap, Map> {
  const HasMapSerializer();

  @override
  get encoder => const HasMapEncoder();
  @override
  get decoder => const HasMapDecoder();
  static HasMap fromMap(Map map) {
    return HasMap(
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
  static const List<String> allFields = <String>[value, list];

  static const String value = 'value';

  static const String list = 'list';
}
