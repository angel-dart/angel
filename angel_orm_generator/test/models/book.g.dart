// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.book;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Book extends _Book {
  @override
  String id;

  @override
  Author author;

  @override
  int authorId;

  @override
  String name;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Book(
      {this.id,
      this.author,
      this.authorId,
      this.name,
      this.createdAt,
      this.updatedAt});

  factory Book.fromJson(Map data) {
    return new Book(
        id: data['id'],
        author: data['author'] == null
            ? null
            : (data['author'] is Author
                ? data['author']
                : new Author.fromJson(data['author'])),
        authorId: data['author_id'],
        name: data['name'],
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
        'author_id': authorId,
        'name': name,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Book parse(Map map) => new Book.fromJson(map);

  Book clone() {
    return new Book.fromJson(toJson());
  }
}
