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
      this.createdAt,
      this.updatedAt});

  final String id;

  final String name;

  final int age;

  final List<Book> books;

  final Book newestBook;

  final DateTime createdAt;

  final DateTime updatedAt;
}

class Library extends _Library {
  Library({this.id, this.collection, this.createdAt, this.updatedAt});

  final String id;

  final Map<String, Book> collection;

  final DateTime createdAt;

  final DateTime updatedAt;
}
