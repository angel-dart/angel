// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.author;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Author extends _Author {
  Author(
      {this.id,
      @required this.name,
      @required this.age,
      List<Book> books,
      this.newestBook,
      this.secret,
      this.obscured,
      this.createdAt,
      this.updatedAt})
      : this.books = new List.unmodifiable(books ?? []);

  @override
  final String id;

  @override
  final String name;

  @override
  final int age;

  @override
  final List<Book> books;

  @override
  final Book newestBook;

  @override
  final String secret;

  @override
  final String obscured;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Author copyWith(
      {String id,
      String name,
      int age,
      List<Book> books,
      Book newestBook,
      String secret,
      String obscured,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Author(
        id: id ?? this.id,
        name: name ?? this.name,
        age: age ?? this.age,
        books: books ?? this.books,
        newestBook: newestBook ?? this.newestBook,
        secret: secret ?? this.secret,
        obscured: obscured ?? this.obscured,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Author &&
        other.id == id &&
        other.name == name &&
        other.age == age &&
        const ListEquality<Book>(const DefaultEquality<Book>())
            .equals(other.books, books) &&
        other.newestBook == newestBook &&
        other.secret == secret &&
        other.obscured == obscured &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([
      id,
      name,
      age,
      books,
      newestBook,
      secret,
      obscured,
      createdAt,
      updatedAt
    ]);
  }

  Map<String, dynamic> toJson() {
    return AuthorSerializer.toMap(this);
  }
}

@generatedSerializable
class Library extends _Library {
  Library(
      {this.id, Map<String, Book> collection, this.createdAt, this.updatedAt})
      : this.collection = new Map.unmodifiable(collection ?? {});

  @override
  final String id;

  @override
  final Map<String, Book> collection;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Library copyWith(
      {String id,
      Map<String, Book> collection,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Library(
        id: id ?? this.id,
        collection: collection ?? this.collection,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Library &&
        other.id == id &&
        const MapEquality<String, Book>(
                keys: const DefaultEquality<String>(),
                values: const DefaultEquality<Book>())
            .equals(other.collection, collection) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, collection, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return LibrarySerializer.toMap(this);
  }
}

@generatedSerializable
class Bookmark extends _Bookmark {
  Bookmark(Book book,
      {this.id,
      List<int> history,
      @required this.page,
      this.comment,
      this.createdAt,
      this.updatedAt})
      : this.history = new List.unmodifiable(history ?? []),
        super(book);

  @override
  final String id;

  @override
  final List<int> history;

  @override
  final int page;

  @override
  final String comment;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Bookmark copyWith(Book book,
      {String id,
      List<int> history,
      int page,
      String comment,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Bookmark(book,
        id: id ?? this.id,
        history: history ?? this.history,
        page: page ?? this.page,
        comment: comment ?? this.comment,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Bookmark &&
        other.id == id &&
        const ListEquality<int>(const DefaultEquality<int>())
            .equals(other.history, history) &&
        other.page == page &&
        other.comment == comment &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, history, page, comment, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return BookmarkSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class AuthorSerializer {
  static Author fromMap(Map map) {
    if (map['name'] == null) {
      throw new FormatException("Missing required field 'name' on Author.");
    }

    if (map['age'] == null) {
      throw new FormatException("Custom message for missing `age`");
    }

    return new Author(
        id: map['id'] as String,
        name: map['name'] as String,
        age: map['age'] as int,
        books: map['books'] is Iterable
            ? new List.unmodifiable(((map['books'] as Iterable)
                    .where((x) => x is Map) as Iterable<Map>)
                .map(BookSerializer.fromMap))
            : null,
        newestBook: map['newest_book'] != null
            ? BookSerializer.fromMap(map['newest_book'] as Map)
            : null,
        obscured: map['obscured'] as String,
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
    if (model.name == null) {
      throw new FormatException("Missing required field 'name' on Author.");
    }

    if (model.age == null) {
      throw new FormatException("Custom message for missing `age`");
    }

    return {
      'id': model.id,
      'name': model.name,
      'age': model.age,
      'books': model.books?.map((m) => m.toJson())?.toList(),
      'newest_book': BookSerializer.toMap(model.newestBook),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class AuthorFields {
  static const List<String> allFields = const <String>[
    id,
    name,
    age,
    books,
    newestBook,
    secret,
    obscured,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String name = 'name';

  static const String age = 'age';

  static const String books = 'books';

  static const String newestBook = 'newest_book';

  static const String secret = 'secret';

  static const String obscured = 'obscured';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

abstract class LibrarySerializer {
  static Library fromMap(Map map) {
    return new Library(
        id: map['id'] as String,
        collection: map['collection'] is Map
            ? new Map.unmodifiable(
                (map['collection'] as Map).keys.fold({}, (out, key) {
                return out
                  ..[key] = BookSerializer.fromMap(
                      ((map['collection'] as Map)[key]) as Map);
              }))
            : null,
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

  static Map<String, dynamic> toMap(Library model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'collection': model.collection.keys?.fold({}, (map, key) {
        return map..[key] = BookSerializer.toMap(model.collection[key]);
      }),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class LibraryFields {
  static const List<String> allFields = const <String>[
    id,
    collection,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String collection = 'collection';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

abstract class BookmarkSerializer {
  static Bookmark fromMap(Map map, Book book) {
    if (map['page'] == null) {
      throw new FormatException("Missing required field 'page' on Bookmark.");
    }

    return new Bookmark(book,
        id: map['id'] as String,
        history: map['history'] is Iterable
            ? (map['history'] as Iterable).cast<int>().toList()
            : null,
        page: map['page'] as int,
        comment: map['comment'] as String,
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

  static Map<String, dynamic> toMap(Bookmark model) {
    if (model == null) {
      return null;
    }
    if (model.page == null) {
      throw new FormatException("Missing required field 'page' on Bookmark.");
    }

    return {
      'id': model.id,
      'history': model.history,
      'page': model.page,
      'comment': model.comment,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class BookmarkFields {
  static const List<String> allFields = const <String>[
    id,
    history,
    page,
    comment,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String history = 'history';

  static const String page = 'page';

  static const String comment = 'comment';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
