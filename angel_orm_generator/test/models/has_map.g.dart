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
    return const ['value'];
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
    var model = new HasMap(value: (row[0] as Map<dynamic, dynamic>));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class HasMapQueryWhere extends QueryWhere {
  HasMapQueryWhere(HasMapQuery query)
      : value = new MapSqlExpressionBuilder(query, 'value');

  final MapSqlExpressionBuilder value;

  @override
  get expressionBuilders {
    return [value];
  }
}

class HasMapQueryValues extends MapQueryValues {
  Map<dynamic, dynamic> get value {
    return (values['value'] as Map<dynamic, dynamic>);
  }

  set value(Map<dynamic, dynamic> value) => values['value'] = value;
  void copyFrom(HasMap model) {
    values.addAll({'value': model.value});
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class HasMap implements _HasMap {
  const HasMap({Map<dynamic, dynamic> this.value});

  @override
  final Map<dynamic, dynamic> value;

  HasMap copyWith({Map<dynamic, dynamic> value}) {
    return new HasMap(value: value ?? this.value);
  }

  bool operator ==(other) {
    return other is _HasMap &&
        const MapEquality<dynamic, dynamic>(
                keys: const DefaultEquality(), values: const DefaultEquality())
            .equals(other.value, value);
  }

  @override
  int get hashCode {
    return hashObjects([value]);
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
            : null);
  }

  static Map<String, dynamic> toMap(_HasMap model) {
    if (model == null) {
      return null;
    }
    return {'value': model.value};
  }
}

abstract class HasMapFields {
  static const List<String> allFields = const <String>[value];

  static const String value = 'value';
}
