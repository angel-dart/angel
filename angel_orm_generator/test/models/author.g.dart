// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.author;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class AuthorQuery extends Query<Author, AuthorQueryWhere> {
  @override
  final AuthorQueryWhere where = new AuthorQueryWhere();

  @override
  get tableName {
    return 'authors';
  }

  @override
  get fields {
    return AuthorFields.allFields;
  }

  @override
  deserialize(List row) {
    return new Author(
        id: row[0].toString(),
        name: (row[1] as String),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
  }
}

class AuthorQueryWhere extends QueryWhere {
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

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Author extends _Author {
  Author({this.id, this.name, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Author copyWith(
      {String id, String name, DateTime createdAt, DateTime updatedAt}) {
    return new Author(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Author &&
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
    return AuthorSerializer.toMap(this);
  }
}
