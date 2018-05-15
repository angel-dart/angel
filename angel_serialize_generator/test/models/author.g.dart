// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.author;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

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

  Map<String, dynamic> toJson() {
    return AuthorSerializer.toMap(this);
  }
}

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

  Map<String, dynamic> toJson() {
    return LibrarySerializer.toMap(this);
  }
}

class Bookmark extends _Bookmark {
  Bookmark(Book book,
      {this.id,
      List<int> history,
      this.page,
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

  Map<String, dynamic> toJson() {
    return BookmarkSerializer.toMap(this);
  }
}
