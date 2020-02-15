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
      this.createdAt,
      this.updatedAt,
      this.author,
      this.title,
      this.description,
      this.pageCount,
      List<double> notModels,
      this.camelCaseString})
      : this.notModels = List.unmodifiable(notModels ?? []);

  /// A unique identifier corresponding to this item.
  @override
  String id;

  /// The time at which this item was created.
  @override
  DateTime createdAt;

  /// The last time at which this item was updated.
  @override
  DateTime updatedAt;

  @override
  String author;

  @override
  String title;

  @override
  String description;

  /// The number of pages the book has.
  @override
  int pageCount;

  @override
  List<double> notModels;

  @override
  String camelCaseString;

  Book copyWith(
      {String id,
      DateTime createdAt,
      DateTime updatedAt,
      String author,
      String title,
      String description,
      int pageCount,
      List<double> notModels,
      String camelCaseString}) {
    return Book(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        author: author ?? this.author,
        title: title ?? this.title,
        description: description ?? this.description,
        pageCount: pageCount ?? this.pageCount,
        notModels: notModels ?? this.notModels,
        camelCaseString: camelCaseString ?? this.camelCaseString);
  }

  bool operator ==(other) {
    return other is _Book &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.author == author &&
        other.title == title &&
        other.description == description &&
        other.pageCount == pageCount &&
        ListEquality<double>(DefaultEquality<double>())
            .equals(other.notModels, notModels) &&
        other.camelCaseString == camelCaseString;
  }

  @override
  int get hashCode {
    return hashObjects([
      id,
      createdAt,
      updatedAt,
      author,
      title,
      description,
      pageCount,
      notModels,
      camelCaseString
    ]);
  }

  @override
  String toString() {
    return "Book(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, author=$author, title=$title, description=$description, pageCount=$pageCount, notModels=$notModels, camelCaseString=$camelCaseString)";
  }

  Map<String, dynamic> toJson() {
    return BookSerializer.toMap(this);
  }
}

@generatedSerializable
class Author extends _Author {
  Author(
      {this.id,
      this.createdAt,
      this.updatedAt,
      @required this.name,
      @required this.age,
      List<_Book> books,
      this.newestBook,
      this.secret,
      this.obscured})
      : this.books = List.unmodifiable(books ?? []);

  /// A unique identifier corresponding to this item.
  @override
  String id;

  /// The time at which this item was created.
  @override
  DateTime createdAt;

  /// The last time at which this item was updated.
  @override
  DateTime updatedAt;

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

  Author copyWith(
      {String id,
      DateTime createdAt,
      DateTime updatedAt,
      String name,
      int age,
      List<_Book> books,
      _Book newestBook,
      String secret,
      String obscured}) {
    return Author(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        name: name ?? this.name,
        age: age ?? this.age,
        books: books ?? this.books,
        newestBook: newestBook ?? this.newestBook,
        secret: secret ?? this.secret,
        obscured: obscured ?? this.obscured);
  }

  bool operator ==(other) {
    return other is _Author &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.name == name &&
        other.age == age &&
        ListEquality<_Book>(DefaultEquality<_Book>())
            .equals(other.books, books) &&
        other.newestBook == newestBook &&
        other.secret == secret &&
        other.obscured == obscured;
  }

  @override
  int get hashCode {
    return hashObjects([
      id,
      createdAt,
      updatedAt,
      name,
      age,
      books,
      newestBook,
      secret,
      obscured
    ]);
  }

  @override
  String toString() {
    return "Author(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, name=$name, age=$age, books=$books, newestBook=$newestBook, secret=$secret, obscured=$obscured)";
  }

  Map<String, dynamic> toJson() {
    return AuthorSerializer.toMap(this);
  }
}

@generatedSerializable
class Library extends _Library {
  Library(
      {this.id, this.createdAt, this.updatedAt, Map<String, _Book> collection})
      : this.collection = Map.unmodifiable(collection ?? {});

  /// A unique identifier corresponding to this item.
  @override
  String id;

  /// The time at which this item was created.
  @override
  DateTime createdAt;

  /// The last time at which this item was updated.
  @override
  DateTime updatedAt;

  @override
  final Map<String, _Book> collection;

  Library copyWith(
      {String id,
      DateTime createdAt,
      DateTime updatedAt,
      Map<String, _Book> collection}) {
    return Library(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        collection: collection ?? this.collection);
  }

  bool operator ==(other) {
    return other is _Library &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        MapEquality<String, _Book>(
                keys: DefaultEquality<String>(),
                values: DefaultEquality<_Book>())
            .equals(other.collection, collection);
  }

  @override
  int get hashCode {
    return hashObjects([id, createdAt, updatedAt, collection]);
  }

  @override
  String toString() {
    return "Library(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, collection=$collection)";
  }

  Map<String, dynamic> toJson() {
    return LibrarySerializer.toMap(this);
  }
}

@generatedSerializable
class Bookmark extends _Bookmark {
  Bookmark(_Book book,
      {this.id,
      this.createdAt,
      this.updatedAt,
      List<int> history,
      @required this.page,
      this.comment})
      : this.history = List.unmodifiable(history ?? []),
        super(book);

  /// A unique identifier corresponding to this item.
  @override
  String id;

  /// The time at which this item was created.
  @override
  DateTime createdAt;

  /// The last time at which this item was updated.
  @override
  DateTime updatedAt;

  @override
  final List<int> history;

  @override
  final int page;

  @override
  final String comment;

  Bookmark copyWith(_Book book,
      {String id,
      DateTime createdAt,
      DateTime updatedAt,
      List<int> history,
      int page,
      String comment}) {
    return Bookmark(book,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        history: history ?? this.history,
        page: page ?? this.page,
        comment: comment ?? this.comment);
  }

  bool operator ==(other) {
    return other is _Bookmark &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        ListEquality<int>(DefaultEquality<int>())
            .equals(other.history, history) &&
        other.page == page &&
        other.comment == comment;
  }

  @override
  int get hashCode {
    return hashObjects([id, createdAt, updatedAt, history, page, comment]);
  }

  @override
  String toString() {
    return "Bookmark(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, history=$history, page=$page, comment=$comment)";
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
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null,
        author: map['author'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        pageCount: map['page_count'] as int,
        notModels: map['not_models'] is Iterable
            ? (map['not_models'] as Iterable).cast<double>().toList()
            : null,
        camelCaseString: map['camelCase'] as String);
  }

  static Map<String, dynamic> toMap(_Book model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'author': model.author,
      'title': model.title,
      'description': model.description,
      'page_count': model.pageCount,
      'not_models': model.notModels,
      'camelCase': model.camelCaseString
    };
  }
}

abstract class BookFields {
  static const List<String> allFields = <String>[
    id,
    createdAt,
    updatedAt,
    author,
    title,
    description,
    pageCount,
    notModels,
    camelCaseString
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String author = 'author';

  static const String title = 'title';

  static const String description = 'description';

  static const String pageCount = 'page_count';

  static const String notModels = 'not_models';

  static const String camelCaseString = 'camelCase';
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
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null,
        name: map['name'] as String,
        age: map['age'] as int,
        books: map['books'] is Iterable
            ? List.unmodifiable(((map['books'] as Iterable).whereType<Map>())
                .map(BookSerializer.fromMap))
            : null,
        newestBook: map['newest_book'] != null
            ? BookSerializer.fromMap(map['newest_book'] as Map)
            : null,
        obscured: map['obscured'] as String);
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
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'name': model.name,
      'age': model.age,
      'books': model.books?.map((m) => BookSerializer.toMap(m))?.toList(),
      'newest_book': BookSerializer.toMap(model.newestBook)
    };
  }
}

abstract class AuthorFields {
  static const List<String> allFields = <String>[
    id,
    createdAt,
    updatedAt,
    name,
    age,
    books,
    newestBook,
    secret,
    obscured
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String name = 'name';

  static const String age = 'age';

  static const String books = 'books';

  static const String newestBook = 'newest_book';

  static const String secret = 'secret';

  static const String obscured = 'obscured';
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
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null,
        collection: map['collection'] is Map
            ? Map.unmodifiable(
                (map['collection'] as Map).keys.fold({}, (out, key) {
                return out
                  ..[key] = BookSerializer.fromMap(
                      ((map['collection'] as Map)[key]) as Map);
              }))
            : null);
  }

  static Map<String, dynamic> toMap(_Library model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'collection': model.collection.keys?.fold({}, (map, key) {
        return map..[key] = BookSerializer.toMap(model.collection[key]);
      })
    };
  }
}

abstract class LibraryFields {
  static const List<String> allFields = <String>[
    id,
    createdAt,
    updatedAt,
    collection
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String collection = 'collection';
}

abstract class BookmarkSerializer {
  static Bookmark fromMap(Map map, _Book book) {
    if (map['page'] == null) {
      throw FormatException("Missing required field 'page' on Bookmark.");
    }

    return Bookmark(book,
        id: map['id'] as String,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null,
        history: map['history'] is Iterable
            ? (map['history'] as Iterable).cast<int>().toList()
            : null,
        page: map['page'] as int,
        comment: map['comment'] as String);
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
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'history': model.history,
      'page': model.page,
      'comment': model.comment
    };
  }
}

abstract class BookmarkFields {
  static const List<String> allFields = <String>[
    id,
    createdAt,
    updatedAt,
    history,
    page,
    comment
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String history = 'history';

  static const String page = 'page';

  static const String comment = 'comment';
}
