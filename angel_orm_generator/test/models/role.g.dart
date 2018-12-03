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
    return RoleFields.allFields;
  }

  @override
  RoleQueryWhere newWhereClause() {
    return new RoleQueryWhere();
  }

  @override
  deserialize(List row) {
    return new Role(
        id: row[0].toString(),
        name: (row[1] as String),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
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
