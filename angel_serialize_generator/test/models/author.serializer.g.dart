// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.author;

// **************************************************************************
// Generator: SerializerGenerator
// **************************************************************************

abstract class AuthorSerializer {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'books': books,
      'newest_book': newestBook,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String()
    };
  }
}

abstract class LibrarySerializer {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection': collection,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String()
    };
  }
}
