// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.book;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class BookQuery extends Query<Book, BookQueryWhere> {
  BookQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = BookQueryWhere(this);
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
    return const ['id'];
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
    var model = Book(id: row[0].toString());
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class BookQueryWhere extends QueryWhere {
  BookQueryWhere(BookQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id');

  final NumericSqlExpressionBuilder<int> id;

  @override
  get expressionBuilders {
    return [id];
  }
}

class BookQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  void copyFrom(Book model) {}
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Book extends _Book {
  Book(
      {this.id,
      this.author,
      this.partnerAuthor,
      this.name,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final dynamic author;

  @override
  final dynamic partnerAuthor;

  @override
  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Book copyWith(
      {String id,
      dynamic author,
      dynamic partnerAuthor,
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
    return new Book(
        id: map['id'] as String,
        author: map['author'] as dynamic,
        partnerAuthor: map['partner_author'] as dynamic,
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
    return {
      'id': model.id,
      'author': model.author,
      'partner_author': model.partnerAuthor,
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
