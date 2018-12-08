// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.role;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class RoleQuery extends Query<Role, RoleQueryWhere> {
  @override
  final RoleQueryValues values = new RoleQueryValues();

  @override
  final RoleQueryWhere where = new RoleQueryWhere();

  @override
  get tableName {
    return 'roles';
  }

  @override
  get fields {
    return const ['id', 'name', 'created_at', 'updated_at'];
  }

  @override
  RoleQueryWhere newWhereClause() {
    return new RoleQueryWhere();
  }

  static Role parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Role(
        id: row[0].toString(),
        name: (row[1] as String),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class RoleQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final StringSqlExpressionBuilder name =
      new StringSqlExpressionBuilder('name');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [id, name, createdAt, updatedAt];
  }
}

class RoleQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  String get name {
    return (values['name'] as String);
  }

  void set name(String value) => values['name'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  void set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  void set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Role model) {
    values.addAll({
      'name': model.name,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Role extends _Role {
  Role({this.id, this.name, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Role copyWith(
      {String id, String name, DateTime createdAt, DateTime updatedAt}) {
    return new Role(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Role &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, name, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return RoleSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class RoleSerializer {
  static Role fromMap(Map map) {
    return new Role(
        id: map['id'] as String,
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

  static Map<String, dynamic> toMap(Role model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'name': model.name,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class RoleFields {
  static const List<String> allFields = const <String>[
    id,
    name,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String name = 'name';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
