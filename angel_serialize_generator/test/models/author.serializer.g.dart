// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.author;

// **************************************************************************
// Generator: SerializerGenerator
// **************************************************************************

abstract class AuthorSerializer {
  static Author fromMap(Map map) {
    if (map['name'] == null) {
      throw new FormatException("Missing required field 'name' on Author.");
    }

    if (map['age'] == null) {
      throw new FormatException("Custom message for missing `age`");
    }

    return new Author(
        id: map['id'] as String,
        name: map['name'] as String,
        age: map['age'] as int,
        books: map['books'] is Iterable
            ? new List.unmodifiable(((map['books'] as Iterable)
                    .where((x) => x is Map) as Iterable<Map>)
                .map(BookSerializer.fromMap))
            : null,
        newestBook: map['newest_book'] != null
            ? BookSerializer.fromMap(map['newest_book'])
            : null,
        obscured: map['obscured'] as String,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at']))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at']))
            : null);
  }

  static Map<String, dynamic> toMap(Author model) {
    if (model == null) {
      return null;
    }
    if (model.name == null) {
      throw new FormatException("Missing required field 'name' on Author.");
    }

    if (model.age == null) {
      throw new FormatException("Custom message for missing `age`");
    }

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

abstract class AuthorFields {
  static const String id = 'id';

  static const String name = 'name';

  static const String age = 'age';

  static const String books = 'books';

  static const String newestBook = 'newest_book';

  static const String secret = 'secret';

  static const String obscured = 'obscured';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

abstract class LibrarySerializer {
  static Library fromMap(Map map) {
    return new Library(
        id: map['id'] as String,
        collection: map['collection'] is Map
            ? new Map.unmodifiable(
                (map['collection'] as Map).keys.fold({}, (out, key) {
                return out
                  ..[key] =
                      BookSerializer.fromMap((map['collection'] as Map)[key]);
              }))
            : null,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at']))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at']))
            : null);
  }

  static Map<String, dynamic> toMap(Library model) {
    if (model == null) {
      return null;
    }
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

abstract class LibraryFields {
  static const String id = 'id';

  static const String collection = 'collection';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

abstract class BookmarkSerializer {
  static Bookmark fromMap(Map map, Book book) {
    if (map['page'] == null) {
      throw new FormatException("Missing required field 'page' on Bookmark.");
    }

    return new Bookmark(book,
        id: map['id'] as String,
        history: map['history'] as List<int>,
        page: map['page'] as int,
        comment: map['comment'] as String,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at']))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at']))
            : null);
  }

  static Map<String, dynamic> toMap(Bookmark model) {
    if (model == null) {
      return null;
    }
    if (model.page == null) {
      throw new FormatException("Missing required field 'page' on Bookmark.");
    }

    return {
      'id': model.id,
      'history': model.history,
      'page': model.page,
      'comment': model.comment,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class BookmarkFields {
  static const String id = 'id';

  static const String history = 'history';

  static const String page = 'page';

  static const String comment = 'comment';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
