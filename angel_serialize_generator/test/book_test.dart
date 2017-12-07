import 'dart:convert';
import 'package:test/test.dart';
import 'models/author.dart';
import 'models/book.dart';

const String DEATHLY_HALLOWS_ISBN = '0-545-01022-5';

main() {
  var deathlyHallows = new Book(
      id: '0',
      author: 'J.K. Rowling',
      title: 'Harry Potter and the Deathly Hallows',
      description: 'The 7th book.',
      pageCount: 759,
      updatedAt: new DateTime.now());
  var serializedDeathlyHallows = deathlyHallows.toJson();
  print('Deathly Hallows: $serializedDeathlyHallows');

  var jkRowling = new Author(
      id: '1',
      name: 'J.K. Rowling',
      age: 51,
      books: [deathlyHallows],
      newestBook: deathlyHallows);
  Map serializedJkRowling = JSON.decode(JSON.encode(jkRowling.toJson()));
  Map deathlyHallowsMap = JSON.decode(JSON.encode(serializedDeathlyHallows));
  print('J.K. Rowling: $serializedJkRowling');

  var library = new Library(collection: {DEATHLY_HALLOWS_ISBN: deathlyHallows});
  var serializedLibrary = JSON.decode(JSON.encode(library.toJson()));
  print('Library: $serializedLibrary');

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

    test('heeds @Alias', () {
      expect(serializedDeathlyHallows['page_count'], deathlyHallows.pageCount);
      expect(serializedDeathlyHallows.keys, isNot(contains('pageCount')));
    });

    test('heeds @exclude', () {
      expect(serializedJkRowling.keys, isNot(contains('secret')));
    });

    test('nested @serializable class is serialized', () {
      expect(serializedJkRowling['newest_book'], deathlyHallowsMap);
    });

    test('list of nested @serializable class is serialized', () {
      expect(serializedJkRowling['books'], [deathlyHallowsMap]);
    });

    test('map with @serializable class as second key is serialized', () {
      expect(serializedLibrary['collection'],
          {DEATHLY_HALLOWS_ISBN: deathlyHallowsMap});
    });
  });

  group('deserialization', () {
    test('deserialization sets proper fields', () {
      var book = new Book.fromJson(deathlyHallowsMap);
      expect(book.id, deathlyHallows.id);
      expect(book.author, deathlyHallows.author);
      expect(book.description, deathlyHallows.description);
      expect(book.pageCount, deathlyHallows.pageCount);
      expect(book.createdAt, isNull);
      expect(book.updatedAt, deathlyHallows.updatedAt);
    });

    group('nested @serializable', () {
      var author = new Author.fromJson(serializedJkRowling);

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
        var lib = new Library.fromJson(serializedLibrary);
        expect(lib.collection, allOf(isNotEmpty, hasLength(1)));
        expect(lib.collection.keys.first, DEATHLY_HALLOWS_ISBN);
        var book = lib.collection[DEATHLY_HALLOWS_ISBN];
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
