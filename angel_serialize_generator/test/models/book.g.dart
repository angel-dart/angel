// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.book;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
@pragma('hello')
@SerializableField(alias: 'omg')
class Book extends _Book {
  Book(
      {this.id,
      this.author,
      this.title,
      this.description,
      this.pageCount,
      List<double> notModels,
      this.camelCaseString,
      this.createdAt,
      this.updatedAt})
      : this.notModels = List.unmodifiable(notModels ?? []);

  @override
  final String id;

  @override
  final String author;

  @override
  final String title;

  @override
  final String description;

  /// The number of pages the book has.
  @override
  final int pageCount;

  @override
  final List<double> notModels;

  @override
  final String camelCaseString;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Book copyWith(
      {String id,
      String author,
      String title,
      String description,
      int pageCount,
      List<double> notModels,
      String camelCaseString,
      DateTime createdAt,
      DateTime updatedAt}) {
    return Book(
        id: id ?? this.id,
        author: author ?? this.author,
        title: title ?? this.title,
        description: description ?? this.description,
        pageCount: pageCount ?? this.pageCount,
        notModels: notModels ?? this.notModels,
        camelCaseString: camelCaseString ?? this.camelCaseString,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Book &&
        other.id == id &&
        other.author == author &&
        other.title == title &&
        other.description == description &&
        other.pageCount == pageCount &&
        ListEquality<double>(DefaultEquality<double>())
            .equals(other.notModels, notModels) &&
        other.camelCaseString == camelCaseString &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([
      id,
      author,
      title,
      description,
      pageCount,
      notModels,
      camelCaseString,
      createdAt,
      updatedAt
    ]);
  }

  @override
  String toString() {
    return "Book(id=$id, author=$author, title=$title, description=$description, pageCount=$pageCount, notModels=$notModels, camelCaseString=$camelCaseString, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return BookSerializer.toMap(this);
  }
}

@generatedSerializable
class Author extends _Author {
  Author(
      {this.id,
      @required this.name,
      @required this.age,
      List<_Book> books,
      this.newestBook,
      this.secret,
      this.obscured,
      this.createdAt,
      this.updatedAt})
      : this.books = List.unmodifiable(books ?? []);

  @override
  final String id;

  @override
  final String name;

  @override
  final int age;

  @override
  final List<_Book> books;

  /// The newest book.
  @override
  final _Book newestBook;

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
      List<_Book> books,
      _Book newestBook,
      String secret,
      String obscured,
      DateTime createdAt,
      DateTime updatedAt}) {
    return Author(
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
        ListEquality<_Book>(DefaultEquality<_Book>())
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

  @override
  String toString() {
    return "Author(id=$id, name=$name, age=$age, books=$books, newestBook=$newestBook, secret=$secret, obscured=$obscured, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return AuthorSerializer.toMap(this);
  }
}

@generatedSerializable
class Library extends _Library {
  Library(
      {this.id, Map<String, _Book> collection, this.createdAt, this.updatedAt})
      : this.collection = Map.unmodifiable(collection ?? {});

  @override
  final String id;

  @override
  final Map<String, _Book> collection;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Library copyWith(
      {String id,
      Map<String, _Book> collection,
      DateTime createdAt,
      DateTime updatedAt}) {
    return Library(
        id: id ?? this.id,
        collection: collection ?? this.collection,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Library &&
        other.id == id &&
        MapEquality<String, _Book>(
                keys: DefaultEquality<String>(),
                values: DefaultEquality<_Book>())
            .equals(other.collection, collection) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, collection, createdAt, updatedAt]);
  }

  @override
  String toString() {
    return "Library(id=$id, collection=$collection, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return LibrarySerializer.toMap(this);
  }
}

@generatedSerializable
class Bookmark extends _Bookmark {
  Bookmark(_Book book,
      {this.id,
      List<int> history,
      @required this.page,
      this.comment,
      this.createdAt,
      this.updatedAt})
      : this.history = List.unmodifiable(history ?? []),
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

  Bookmark copyWith(_Book book,
      {String id,
      List<int> history,
      int page,
      String comment,
      DateTime createdAt,
      DateTime updatedAt}) {
    return Bookmark(book,
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
        ListEquality<int>(DefaultEquality<int>())
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

  @override
  String toString() {
    return "Bookmark(id=$id, history=$history, page=$page, comment=$comment, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return BookmarkSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const BookSerializer bookSerializer = BookSerializer();

class BookEncoder extends Converter<Book, Map> {
  const BookEncoder();

  @override
  Map convert(Book model) => BookSerializer.toMap(model);
}

class BookDecoder extends Converter<Map, Book> {
  const BookDecoder();

  @override
  Book convert(Map map) => BookSerializer.fromMap(map);
}

class BookSerializer extends Codec<Book, Map> {
  const BookSerializer();

  @override
  get encoder => const BookEncoder();
  @override
  get decoder => const BookDecoder();
  static Book fromMap(Map map) {
    return Book(
        id: map['id'] as String,
        author: map['author'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        pageCount: map['page_count'] as int,
        notModels: map['not_models'] is Iterable
            ? (map['not_models'] as Iterable).cast<double>().toList()
            : null,
        camelCaseString: map['camelCase'] as String,
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
      'title': model.title,
      'description': model.description,
      'page_count': model.pageCount,
      'not_models': model.notModels,
      'camelCase': model.camelCaseString,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class BookFields {
  static const List<String> allFields = <String>[
    id,
    author,
    title,
    description,
    pageCount,
    notModels,
    camelCaseString,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String author = 'author';

  static const String title = 'title';

  static const String description = 'description';

  static const String pageCount = 'page_count';

  static const String notModels = 'not_models';

  static const String camelCaseString = 'camelCase';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

const AuthorSerializer authorSerializer = AuthorSerializer();

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
    if (map['name'] == null) {
      throw FormatException("Missing required field 'name' on Author.");
    }

    if (map['age'] == null) {
      throw FormatException("Custom message for missing `age`");
    }

    return Author(
        id: map['id'] as String,
        name: map['name'] as String,
        age: map['age'] as int,
        books: map['books'] is Iterable
            ? List.unmodifiable(
                ((map['books'] as Iterable).where((x) => x is Map))
                    .cast<Map>()
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

  static Map<String, dynamic> toMap(_Author model) {
    if (model == null) {
      return null;
    }
    if (model.name == null) {
      throw FormatException("Missing required field 'name' on Author.");
    }

    if (model.age == null) {
      throw FormatException("Custom message for missing `age`");
    }

    return {
      'id': model.id,
      'name': model.name,
      'age': model.age,
      'books': model.books?.map((m) => BookSerializer.toMap(m))?.toList(),
      'newest_book': BookSerializer.toMap(model.newestBook),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class AuthorFields {
  static const List<String> allFields = <String>[
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

const LibrarySerializer librarySerializer = LibrarySerializer();

class LibraryEncoder extends Converter<Library, Map> {
  const LibraryEncoder();

  @override
  Map convert(Library model) => LibrarySerializer.toMap(model);
}

class LibraryDecoder extends Converter<Map, Library> {
  const LibraryDecoder();

  @override
  Library convert(Map map) => LibrarySerializer.fromMap(map);
}

class LibrarySerializer extends Codec<Library, Map> {
  const LibrarySerializer();

  @override
  get encoder => const LibraryEncoder();
  @override
  get decoder => const LibraryDecoder();
  static Library fromMap(Map map) {
    return Library(
        id: map['id'] as String,
        collection: map['collection'] is Map
            ? Map.unmodifiable(
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

  static Map<String, dynamic> toMap(_Library model) {
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
  static const List<String> allFields = <String>[
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
  static Bookmark fromMap(Map map, _Book book) {
    if (map['page'] == null) {
      throw FormatException("Missing required field 'page' on Bookmark.");
    }

    return Bookmark(book,
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

  static Map<String, dynamic> toMap(_Bookmark model) {
    if (model == null) {
      return null;
    }
    if (model.page == null) {
      throw FormatException("Missing required field 'page' on Bookmark.");
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
  static const List<String> allFields = <String>[
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
