import 'package:test/test.dart';
import 'models/book.dart';

const String deathlyHallowsIsbn = '0-545-01022-5';

main() {
  var deathlyHallows = Book(
      id: '0',
      author: 'J.K. Rowling',
      title: 'Harry Potter and the Deathly Hallows',
      description: 'The 7th book.',
      pageCount: 759,
      notModels: [1.0, 3.0],
      updatedAt: DateTime.now());
  var serializedDeathlyHallows = deathlyHallows.toJson();
  print('Deathly Hallows: $deathlyHallows');

  var jkRowling = Author(
      id: '1',
      name: 'J.K. Rowling',
      age: 51,
      books: [deathlyHallows],
      newestBook: deathlyHallows);
  var serializedJkRowling = authorSerializer.encode(jkRowling);
  var deathlyHallowsMap = bookSerializer.encode(deathlyHallows);
  print('J.K. Rowling: $jkRowling');

  var library = Library(collection: {deathlyHallowsIsbn: deathlyHallows});
  var serializedLibrary = LibrarySerializer.toMap(library);
  print('Library: $library');

  group('serialization', () {
    test('serialization sets proper fields', () {
      expect(serializedDeathlyHallows['id'], deathlyHallows.id);
      expect(serializedDeathlyHallows['author'], deathlyHallows.author);
      expect(
          serializedDeathlyHallows['description'], deathlyHallows.description);
      expect(serializedDeathlyHallows['page_count'], deathlyHallows.pageCount);
      expect(serializedDeathlyHallows['created_at'], isNull);
      expect(serializedDeathlyHallows['updated_at'],
          deathlyHallows.updatedAt.toIso8601String());
    });

    test('can be mutated', () {
      var b = deathlyHallows.copyWith();
      b.author = 'Hey';
      expect(b.author, 'Hey');
      expect(b.toJson()[BookFields.author], 'Hey');
    });

    test('heeds @Alias', () {
      expect(serializedDeathlyHallows['page_count'], deathlyHallows.pageCount);
      expect(serializedDeathlyHallows.keys, isNot(contains('pageCount')));
    });

    test('standard list', () {
      expect(serializedDeathlyHallows['not_models'], deathlyHallows.notModels);
    });

    test('heeds @exclude', () {
      expect(serializedJkRowling.keys, isNot(contains('secret')));
    });

    test('heeds canDeserialize', () {
      var map = Map.from(serializedJkRowling)..['obscured'] = 'foo';
      var author = authorSerializer.decode(map);
      expect(author.obscured, 'foo');
    });

    test('heeds canSerialize', () {
      expect(serializedJkRowling.keys, isNot(contains('obscured')));
    });

    test('nested @serializable class is serialized', () {
      expect(serializedJkRowling['newest_book'], deathlyHallowsMap);
    });

    test('list of nested @serializable class is serialized', () {
      expect(serializedJkRowling['books'], [deathlyHallowsMap]);
    });

    test('map with @serializable class as second key is serialized', () {
      expect(serializedLibrary['collection'],
          {deathlyHallowsIsbn: deathlyHallowsMap});
    });
  });

  test('fields', () {
    expect(BookFields.author, 'author');
    expect(BookFields.notModels, 'not_models');
    expect(BookFields.camelCaseString, 'camelCase');
  });

  test('equals', () {
    expect(jkRowling.copyWith(), jkRowling);
    expect(deathlyHallows.copyWith(), deathlyHallows);
    expect(library.copyWith(), library);
  });

  test('custom method', () {
    expect(jkRowling.customMethod, 'hey!');
  });

  test('required fields fromMap', () {
    expect(() => AuthorSerializer.fromMap({}), throwsFormatException);
  });

  test('required fields toMap', () {
    var author = Author(name: null, age: 24);
    expect(() => author.toJson(), throwsFormatException);
  });

  group('deserialization', () {
    test('deserialization sets proper fields', () {
      var book = BookSerializer.fromMap(deathlyHallowsMap);
      expect(book.id, deathlyHallows.id);
      expect(book.author, deathlyHallows.author);
      expect(book.description, deathlyHallows.description);
      expect(book.pageCount, deathlyHallows.pageCount);
      expect(book.notModels, deathlyHallows.notModels);
      expect(book.createdAt, isNull);
      expect(book.updatedAt, deathlyHallows.updatedAt);
    });

    group('nested @serializable', () {
      var author = AuthorSerializer.fromMap(serializedJkRowling);

      test('nested @serializable class is deserialized', () {
        var newestBook = author.newestBook;
        expect(newestBook, isNotNull);
        expect(newestBook.id, deathlyHallows.id);
        expect(newestBook.pageCount, deathlyHallows.pageCount);
        expect(newestBook.updatedAt, deathlyHallows.updatedAt);
      });

      test('list of nested @serializable class is deserialized', () {
        expect(author.books, allOf(isList, isNotEmpty, hasLength(1)));
        var book = author.books.first;
        expect(book.id, deathlyHallows.id);
        expect(book.author, deathlyHallows.author);
        expect(book.description, deathlyHallows.description);
        expect(book.pageCount, deathlyHallows.pageCount);
        expect(book.createdAt, isNull);
        expect(book.updatedAt, deathlyHallows.updatedAt);
      });

      test('map with @serializable class as second key is deserialized', () {
        var lib = LibrarySerializer.fromMap(serializedLibrary);
        expect(lib.collection, allOf(isNotEmpty, hasLength(1)));
        expect(lib.collection.keys.first, deathlyHallowsIsbn);
        var book = lib.collection[deathlyHallowsIsbn];
        expect(book.id, deathlyHallows.id);
        expect(book.author, deathlyHallows.author);
        expect(book.description, deathlyHallows.description);
        expect(book.pageCount, deathlyHallows.pageCount);
        expect(book.createdAt, isNull);
        expect(book.updatedAt, deathlyHallows.updatedAt);
      });
    });
  });
}
