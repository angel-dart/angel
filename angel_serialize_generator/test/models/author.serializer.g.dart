// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.author;

// **************************************************************************
// Generator: SerializerGenerator
// **************************************************************************

abstract class AuthorSerializer {
  static Map<String, dynamic> toMap(Author model) {
    return {
      'id': model.id,
      'name': model.name,
      'age': model.age,
      'books': model.books.map(BookSerializer.toMap).toList(),
      'newest_book': BookSerializer.toMap(model.newestBook),
      'created_at': model.createdAt.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String()
    };
  }
}

abstract class LibrarySerializer {
  static Map<String, dynamic> toMap(Library model) {
    return {
      'id': model.id,
      'collection': model.collection.keys.fold({}, (map, key) {
        return map..[key] = BookSerializer.toMap(model.collection[key]);
      }),
      'created_at': model.createdAt.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String()
    };
  }
}
