// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.book;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Book extends _Book {
  Book(
      {this.id,
      this.author,
      this.title,
      this.description,
      this.pageCount,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final String author;

  @override
  final String title;

  @override
  final String description;

  @override
  final int pageCount;

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
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Book(
        id: id ?? this.id,
        author: author ?? this.author,
        title: title ?? this.title,
        description: description ?? this.description,
        pageCount: pageCount ?? this.pageCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }
}
