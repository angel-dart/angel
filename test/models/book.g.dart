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
        createdAt: data['createdAt'] is DateTime
            ? data['createdAt']
            : (data['createdAt'] is String
                ? DateTime.parse(data['createdAt'])
                : null),
        updatedAt: data['updatedAt'] is DateTime
            ? data['updatedAt']
            : (data['updatedAt'] is String
                ? DateTime.parse(data['updatedAt'])
                : null));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'title': title,
        'description': description,
        'page_count': pageCount,
        'createdAt': createdAt == null ? null : createdAt.toIso8601String(),
        'updatedAt': updatedAt == null ? null : updatedAt.toIso8601String()
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
  DateTime createdAt;

  @override
  DateTime updatedAt;

  @override
  List<_Book> books;

  @override
  _Book newestBook;

  @override
  String secret;

  Author(
      {this.id,
      this.name,
      this.age,
      this.createdAt,
      this.updatedAt,
      this.books,
      this.newestBook,
      this.secret});

  factory Author.fromJson(Map data) {
    return new Author(
        id: data['id'],
        name: data['name'],
        age: data['age'],
        createdAt: data['createdAt'] is DateTime
            ? data['createdAt']
            : (data['createdAt'] is String
                ? DateTime.parse(data['createdAt'])
                : null),
        updatedAt: data['updatedAt'] is DateTime
            ? data['updatedAt']
            : (data['updatedAt'] is String
                ? DateTime.parse(data['updatedAt'])
                : null),
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
                : new Book.fromJson(data['newest_book'])));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'createdAt': createdAt == null ? null : createdAt.toIso8601String(),
        'updatedAt': updatedAt == null ? null : updatedAt.toIso8601String(),
        'books': books,
        'newest_book': newestBook
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
  DateTime createdAt;

  @override
  DateTime updatedAt;

  @override
  Map<String, _Book> collection;

  Library({this.id, this.createdAt, this.updatedAt, this.collection});

  factory Library.fromJson(Map data) {
    return new Library(
        id: data['id'],
        createdAt: data['createdAt'] is DateTime
            ? data['createdAt']
            : (data['createdAt'] is String
                ? DateTime.parse(data['createdAt'])
                : null),
        updatedAt: data['updatedAt'] is DateTime
            ? data['updatedAt']
            : (data['updatedAt'] is String
                ? DateTime.parse(data['updatedAt'])
                : null),
        collection: data['collection'] is Map
            ? data['collection'].keys.fold({}, (out, k) {
                out[k] = data['collection'][k] == null
                    ? null
                    : (data['collection'][k] is Book
                        ? data['collection'][k]
                        : new Book.fromJson(data['collection'][k]));
                return out;
              })
            : null);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt == null ? null : createdAt.toIso8601String(),
        'updatedAt': updatedAt == null ? null : updatedAt.toIso8601String(),
        'collection': collection
      };

  static Library parse(Map map) => new Library.fromJson(map);
}
