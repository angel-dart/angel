// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.book;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class BookSerializer {
  static Book fromMap(Map map) {
    return new Book(
        id: map['id'] as String,
        author: map['author'] as dynamic,
        partnerAuthor: map['partner_author'] as dynamic,
        authorId: map['author_id'] as int,
        name: map['name'] as String,
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

  static Map<String, dynamic> toMap(Book model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'author': model.author,
      'partner_author': model.partnerAuthor,
      'author_id': model.authorId,
      'name': model.name,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class BookFields {
  static const List<String> allFields = const <String>[
    id,
    author,
    partnerAuthor,
    authorId,
    name,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String author = 'author';

  static const String partnerAuthor = 'partner_author';

  static const String authorId = 'author_id';

  static const String name = 'name';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
