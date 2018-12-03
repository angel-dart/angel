// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.book;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class BookSerializer {
  static Book fromMap(Map map) {
    return new Book(
        id: map['id'] as String,
        author: map['author'] != null
            ? AuthorSerializer.fromMap(map['author'] as Map)
            : null,
        partnerAuthor: map['partner_author'] != null
            ? AuthorSerializer.fromMap(map['partner_author'] as Map)
            : null,
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
      'author': AuthorSerializer.toMap(model.author),
      'partner_author': AuthorSerializer.toMap(model.partnerAuthor),
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
    name,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String author = 'author';

  static const String partnerAuthor = 'partner_author';

  static const String name = 'name';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
