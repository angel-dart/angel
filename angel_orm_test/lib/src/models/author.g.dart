// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.author;

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class AuthorMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('authors', (table) {
      table.serial('id')..primaryKey();
      table.varChar('name', length: 255)
        ..defaultsTo('Tobe Osakwe')
        ..unique();
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('authors');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class AuthorQuery extends Query<Author, AuthorQueryWhere> {
  AuthorQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = AuthorQueryWhere(this);
  }

  @override
  final AuthorQueryValues values = AuthorQueryValues();

  AuthorQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'authors';
  }

  @override
  get fields {
    return const ['id', 'name', 'created_at', 'updated_at'];
  }

  @override
  AuthorQueryWhere get where {
    return _where;
  }

  @override
  AuthorQueryWhere newWhereClause() {
    return AuthorQueryWhere(this);
  }

  static Author parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Author(
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
  AuthorQueryWhere(AuthorQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        name = StringSqlExpressionBuilder(query, 'name'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final StringSqlExpressionBuilder name;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, name, createdAt, updatedAt];
  }
}

class AuthorQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  String get id {
    return (values['id'] as String);
  }

  set id(String value) => values['id'] = value;
  String get name {
    return (values['name'] as String);
  }

  set name(String value) => values['name'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Author model) {
    name = model.name;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Author extends _Author {
  Author({this.id, this.name = 'Tobe Osakwe', this.createdAt, this.updatedAt});

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

  @override
  String toString() {
    return "Author(id=$id, name=$name, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return AuthorSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const AuthorSerializer authorSerializer = const AuthorSerializer();

class AuthorEncoder extends Converter<Author, Map> {
  const AuthorEncoder();

  @override
  Map convert(Author model) => AuthorSerializer.toMap(model);
}

class AuthorDecoder extends Converter<Map, Author> {
  const AuthorDecoder();

  @override
  Author convert(Map map) => AuthorSerializer.fromMap(map);
}

class AuthorSerializer extends Codec<Author, Map> {
  const AuthorSerializer();

  @override
  get encoder => const AuthorEncoder();
  @override
  get decoder => const AuthorDecoder();
  static Author fromMap(Map map) {
    return new Author(
        id: map['id'] as String,
        name: map['name'] as String ?? 'Tobe Osakwe',
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

  static Map<String, dynamic> toMap(_Author model) {
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
  static const List<String> allFields = <String>[
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
