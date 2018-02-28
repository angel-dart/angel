// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.book;

// **************************************************************************
// Generator: SerializerGenerator
// **************************************************************************

abstract class BookSerializer {
  static Map<String, dynamic> toMap(Book model) {
    return {
      'id': model.id,
      'author': model.author,
      'title': model.title,
      'description': model.description,
      'page_count': model.pageCount,
      'created_at': model.createdAt.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String()
    };
  }
}
