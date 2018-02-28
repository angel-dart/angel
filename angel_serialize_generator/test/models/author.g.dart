// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.author;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Author extends _Author {
  Author(
      {this.id,
      this.name,
      this.age,
      this.books,
      this.newestBook,
      this.secret,
      this.createdAt,
      this.updatedAt});

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
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Author(
        id: id ?? this.id,
        name: name ?? this.name,
        age: age ?? this.age,
        books: books ?? this.books,
        newestBook: newestBook ?? this.newestBook,
        secret: secret ?? this.secret,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }
}

class Library extends _Library {
  Library({this.id, this.collection, this.createdAt, this.updatedAt});

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
}
