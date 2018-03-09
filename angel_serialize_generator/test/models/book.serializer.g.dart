// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.book;

// **************************************************************************
// Generator: SerializerGenerator
// **************************************************************************

abstract class BookSerializer {
  static Book fromMap(Map map) {
    return new Book(
        id: map['id'],
        author: map['author'],
        title: map['title'],
        description: map['description'],
        pageCount: map['page_count'],
        notModels: map['not_models'],
        camelCaseString: map['camelCase'],
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'])
            : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'])
            : null);
  }

  static Map<String, dynamic> toMap(Book model) {
    return {
      'id': model.id,
      'author': model.author,
      'title': model.title,
      'description': model.description,
      'page_count': model.pageCount,
      'not_models': model.notModels,
      'camelCase': model.camelCaseString,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class BookFields {
  static const String id = 'id';

  static const String author = 'author';

  static const String title = 'title';

  static const String description = 'description';

  static const String pageCount = 'page_count';

  static const String notModels = 'not_models';

  static const String camelCaseString = 'camelCase';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
