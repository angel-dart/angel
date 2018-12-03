// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.book;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class BookQuery extends Query<Book, BookQueryWhere> {
  @override
  final BookQueryValues values = new BookQueryValues();

  @override
  final BookQueryWhere where = new BookQueryWhere();

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
  BookQueryWhere newWhereClause() {
    return new BookQueryWhere();
  }

  static Book parseRow(List row) {
    var model = new Book(
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

  @override
  get(executor) {
    leftJoin('authors', 'author_id', 'id',
        additionalFields: const ['name', 'created_at', 'updated_at']);
    leftJoin('authors', 'partner_author_id', 'id',
        additionalFields: const ['name', 'created_at', 'updated_at']);
    return super.get(executor);
  }
}

class BookQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final NumericSqlExpressionBuilder<int> authorId =
      new NumericSqlExpressionBuilder<int>('author_id');

  final NumericSqlExpressionBuilder<int> partnerAuthorId =
      new NumericSqlExpressionBuilder<int>('partner_author_id');

  final StringSqlExpressionBuilder name =
      new StringSqlExpressionBuilder('name');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [id, authorId, partnerAuthorId, name, createdAt, updatedAt];
  }
}

class BookQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  int get authorId {
    return (values['author_id'] as int);
  }

  void set authorId(int value) => values['author_id'] = value;
  int get partnerAuthorId {
    return (values['partner_author_id'] as int);
  }

  void set partnerAuthorId(int value) => values['partner_author_id'] = value;
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
  void copyFrom(Book model) {
    values.addAll({
      'name': model.name,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
    if (model.author != null) {
      values['author_id'] = int.parse(model.author.id);
    }
    if (model.partnerAuthor != null) {
      values['partner_author_id'] = int.parse(model.partnerAuthor.id);
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
      this.author,
      this.partnerAuthor,
      this.name,
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
