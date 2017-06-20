// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.book;

// **************************************************************************
// Generator: JsonModelGenerator
// Target: abstract class _Book
// **************************************************************************

class Book extends _Book {
  @override
  String id;

  @override
  String author;

  @override
  String title;

  @override
  String description;

  @override
  int pageCount;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Book(
      {this.id,
      this.author,
      this.title,
      this.description,
      this.pageCount,
      this.createdAt,
      this.updatedAt});

  factory Book.fromJson(Map data) {
    return new Book(
        id: data['id'],
        author: data['author'],
        title: data['title'],
        description: data['description'],
        pageCount: data['page_count'],
        createdAt: data['created_at'] is DateTime
            ? data['created_at']
            : (data['created_at'] is String
                ? DateTime.parse(data['created_at'])
                : null),
        updatedAt: data['updated_at'] is DateTime
            ? data['updated_at']
            : (data['updated_at'] is String
                ? DateTime.parse(data['updated_at'])
                : null));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'title': title,
        'description': description,
        'page_count': pageCount,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Book parse(Map map) => new Book.fromJson(map);
}

// **************************************************************************
// Generator: JsonModelGenerator
// Target: abstract class _Author
// **************************************************************************

class Author extends _Author {
  @override
  String id;

  @override
  String name;

  @override
  int age;

  @override
  List<_Book> books;

  @override
  _Book newestBook;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Author(
      {this.id,
      this.name,
      this.age,
      this.books,
      this.newestBook,
      this.createdAt,
      this.updatedAt});

  factory Author.fromJson(Map data) {
    return new Author(
        id: data['id'],
        name: data['name'],
        age: data['age'],
        books: data['books'] is List
            ? data['books']
                .map((x) =>
                    x == null ? null : (x is Book ? x : new Book.fromJson(x)))
                .toList()
            : null,
        newestBook: data['newest_book'] == null
            ? null
            : (data['newest_book'] is Book
                ? data['newest_book']
                : new Book.fromJson(data['newest_book'])),
        createdAt: data['created_at'] is DateTime
            ? data['created_at']
            : (data['created_at'] is String
                ? DateTime.parse(data['created_at'])
                : null),
        updatedAt: data['updated_at'] is DateTime
            ? data['updated_at']
            : (data['updated_at'] is String
                ? DateTime.parse(data['updated_at'])
                : null));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'books': books,
        'newest_book': newestBook,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Author parse(Map map) => new Author.fromJson(map);
}

// **************************************************************************
// Generator: JsonModelGenerator
// Target: abstract class _Library
// **************************************************************************

class Library extends _Library {
  @override
  String id;

  @override
  Map<String, _Book> collection;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Library({this.id, this.collection, this.createdAt, this.updatedAt});

  factory Library.fromJson(Map data) {
    return new Library(
        id: data['id'],
        collection: data['collection'] is Map
            ? data['collection'].keys.fold({}, (out, k) {
                out[k] = data['collection'][k] == null
                    ? null
                    : (data['collection'][k] is Book
                        ? data['collection'][k]
                        : new Book.fromJson(data['collection'][k]));
                return out;
              })
            : null,
        createdAt: data['created_at'] is DateTime
            ? data['created_at']
            : (data['created_at'] is String
                ? DateTime.parse(data['created_at'])
                : null),
        updatedAt: data['updated_at'] is DateTime
            ? data['updated_at']
            : (data['updated_at'] is String
                ? DateTime.parse(data['updated_at'])
                : null));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collection': collection,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Library parse(Map map) => new Library.fromJson(map);
}
