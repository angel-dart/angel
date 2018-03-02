// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.author;

// **************************************************************************
// Generator: SerializerGenerator
// **************************************************************************

abstract class AuthorSerializer {
  static Author fromMap(Map map,
      {String id,
      String name,
      int age,
      List<Book> books,
      Book newestBook,
      String obscured,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Author(
        id: map['id'],
        name: map['name'],
        age: map['age'],
        books: map['books'] is Iterable
            ? map['books'].map(BookSerializer.fromMap).toList()
            : null,
        newestBook: map['newest_book'] != null
            ? BookSerializer.fromMap(map['newest_book'])
            : null,
        obscured: map['obscured'],
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'])
            : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'])
            : null);
  }

  static Map<String, dynamic> toMap(Author model) {
    return {
      'id': model.id,
      'name': model.name,
      'age': model.age,
      'books': model.books?.map(BookSerializer.toMap)?.toList(),
      'newest_book': BookSerializer.toMap(model.newestBook),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class LibrarySerializer {
  static Library fromMap(Map map,
      {String id,
      Map<String, Book> collection,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Library(
        id: map['id'],
        collection: map['collection'] is Map
            ? map['collection'].keys.fold({}, (out, key) {
                return out
                  ..[key] = BookSerializer.fromMap(map['collection'][key]);
              })
            : null,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'])
            : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'])
            : null);
  }

  static Map<String, dynamic> toMap(Library model) {
    return {
      'id': model.id,
      'collection': model.collection.keys?.fold({}, (map, key) {
        return map..[key] = BookSerializer.toMap(model.collection[key]);
      }),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}
