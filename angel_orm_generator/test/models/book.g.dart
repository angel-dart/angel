// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.book;

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class BookMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('books', (table) {
      table.serial('id')..primaryKey();
      table.varChar('name');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.integer('author_id').references('authors', 'id');
      table.integer('partner_author_id').references('authors', 'id');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('books');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class BookQuery extends Query<Book, BookQueryWhere> {
  BookQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = BookQueryWhere(this);
    leftJoin('authors', 'author_id', 'id',
        additionalFields: const ['id', 'name', 'created_at', 'updated_at'],
        trampoline: trampoline);
    leftJoin('authors', 'partner_author_id', 'id',
        additionalFields: const ['id', 'name', 'created_at', 'updated_at'],
        trampoline: trampoline);
  }

  @override
  final BookQueryValues values = BookQueryValues();

  BookQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'books';
  }

  @override
  get fields {
    return const [
      'id',
      'author_id',
      'partner_author_id',
      'name',
      'created_at',
      'updated_at'
    ];
  }

  @override
  BookQueryWhere get where {
    return _where;
  }

  @override
  BookQueryWhere newWhereClause() {
    return BookQueryWhere(this);
  }

  static Book parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Book(
        id: row[0].toString(),
        name: (row[3] as String),
        createdAt: (row[4] as DateTime),
        updatedAt: (row[5] as DateTime));
    if (row.length > 6) {
      model =
          model.copyWith(author: AuthorQuery.parseRow(row.skip(6).toList()));
    }
    if (row.length > 10) {
      model = model.copyWith(
          partnerAuthor: AuthorQuery.parseRow(row.skip(10).toList()));
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class BookQueryWhere extends QueryWhere {
  BookQueryWhere(BookQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        authorId = NumericSqlExpressionBuilder<int>(query, 'author_id'),
        partnerAuthorId =
            NumericSqlExpressionBuilder<int>(query, 'partner_author_id'),
        name = StringSqlExpressionBuilder(query, 'name'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final NumericSqlExpressionBuilder<int> authorId;

  final NumericSqlExpressionBuilder<int> partnerAuthorId;

  final StringSqlExpressionBuilder name;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, authorId, partnerAuthorId, name, createdAt, updatedAt];
  }
}

class BookQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  String get id {
    return (values['id'] as String);
  }

  set id(String value) => values['id'] = value;
  int get authorId {
    return (values['author_id'] as int);
  }

  set authorId(int value) => values['author_id'] = value;
  int get partnerAuthorId {
    return (values['partner_author_id'] as int);
  }

  set partnerAuthorId(int value) => values['partner_author_id'] = value;
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
  void copyFrom(Book model) {
    name = model.name;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    if (model.author != null) {
      values['author_id'] = model.author.id;
    }
    if (model.partnerAuthor != null) {
      values['partner_author_id'] = model.partnerAuthor.id;
    }
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Book extends _Book {
  Book(
      {this.id,
      @required this.author,
      @required this.partnerAuthor,
      @required this.name,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final Author author;

  @override
  final Author partnerAuthor;

  @override
  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Book copyWith(
      {String id,
      Author author,
      Author partnerAuthor,
      String name,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Book(
        id: id ?? this.id,
        author: author ?? this.author,
        partnerAuthor: partnerAuthor ?? this.partnerAuthor,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Book &&
        other.id == id &&
        other.author == author &&
        other.partnerAuthor == partnerAuthor &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, author, partnerAuthor, name, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return BookSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class BookSerializer {
  static Book fromMap(Map map) {
    if (map['author'] == null) {
      throw new FormatException("Missing required field 'author' on Book.");
    }

    if (map['partner_author'] == null) {
      throw new FormatException(
          "Missing required field 'partner_author' on Book.");
    }

    if (map['name'] == null) {
      throw new FormatException("Missing required field 'name' on Book.");
    }

    return new Book(
        id: map['id'] as String,
        author: map['author'] != null
            ? AuthorSerializer.fromMap(map['author'] as Map)
            : null,
        partnerAuthor: map['partner_author'] != null
            ? AuthorSerializer.fromMap(map['partner_author'] as Map)
            : null,
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

  static Map<String, dynamic> toMap(_Book model) {
    if (model == null) {
      return null;
    }
    if (model.author == null) {
      throw new FormatException("Missing required field 'author' on Book.");
    }

    if (model.partnerAuthor == null) {
      throw new FormatException(
          "Missing required field 'partner_author' on Book.");
    }

    if (model.name == null) {
      throw new FormatException("Missing required field 'name' on Book.");
    }

    return {
      'id': model.id,
      'author': AuthorSerializer.toMap(model.author),
      'partner_author': AuthorSerializer.toMap(model.partnerAuthor),
      'name': model.name,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class BookFields {
  static const List<String> allFields = <String>[
    id,
    author,
    partnerAuthor,
    name,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String author = 'author';

  static const String partnerAuthor = 'partner_author';

  static const String name = 'name';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
