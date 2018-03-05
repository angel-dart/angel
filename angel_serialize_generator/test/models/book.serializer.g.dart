// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.book;

// **************************************************************************
// Generator: SerializerGenerator
// **************************************************************************

abstract class BookSerializer {
  static Book fromMap(Map map,
      {String id,
      String author,
      String title,
      String description,
      int pageCount,
      List<double> notModels,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Book(
        id: map['id'],
        author: map['author'],
        title: map['title'],
        description: map['description'],
        pageCount: map['page_count'],
        notModels: map['not_models'],
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
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}
