// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.author;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class AuthorQuery extends Query<Author, AuthorQueryWhere> {
  @override
  final AuthorQueryValues values = new AuthorQueryValues();

  @override
  final AuthorQueryWhere where = new AuthorQueryWhere();

  @override
  get tableName {
    return 'authors';
  }

  @override
  get fields {
    return const ['id', 'name', 'created_at', 'updated_at'];
  }

  @override
  AuthorQueryWhere newWhereClause() {
    return new AuthorQueryWhere();
  }

  static Author parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Author(
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

class AuthorQueryValues extends MapQueryValues {
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
  void copyFrom(Author model) {
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

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class AuthorSerializer {
  static Author fromMap(Map map) {
    return new Author(
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

  static Map<String, dynamic> toMap(Author model) {
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

abstract class AuthorFields {
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
