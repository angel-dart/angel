/// Tests for @belongsTo...
library angel_orm_generator.test.book_test;

import 'package:test/test.dart';
import 'models/author.dart';
import 'models/book.dart';
import 'common.dart';

main() {
  PostgresExecutor executor;
  Author jkRowling;
  Author jameson;
  Book deathlyHallows;

  setUp(() async {
    executor = await connectToPostgres(['author', 'book']);

    // Insert an author
    var query = new AuthorQuery()..values.name = 'J.K. Rowling';
    jkRowling = await query.insert(executor);

    query.values.name = 'J.K. Jameson';
    jameson = await query.insert(executor);

    // And a book
    var bookQuery = new BookQuery();
    bookQuery.values
      ..authorId = int.parse(jkRowling.id)
      ..partnerAuthorId = int.parse(jameson.id)
      ..name = 'Deathly Hallows';

    deathlyHallows = await bookQuery.insert(executor);
  });

  tearDown(() => executor.close());

  group('selects', () {
    test('select all', () async {
      var query = new BookQuery();
      var books = await query.get(executor);
      expect(books, hasLength(1));

      var book = books.first;
      print(book.toJson());
      expect(book.id, deathlyHallows.id);
      expect(book.name, deathlyHallows.name);

      var author = book.author;
      print(author.toJson());
      expect(author.id, jkRowling.id);
      expect(author.name, jkRowling.name);
    });

    test('select one', () async {
      var query = new BookQuery();
      query.where.id.equals(int.parse(deathlyHallows.id));
      print(query.compile(Set()));

      var book = await query.getOne(executor);
      print(book.toJson());
      expect(book.id, deathlyHallows.id);
      expect(book.name, deathlyHallows.name);

      var author = book.author;
      print(author.toJson());
      expect(author.id, jkRowling.id);
      expect(author.name, jkRowling.name);
    });

    test('where clause', () async {
      var query = new BookQuery()
        ..where.name.equals('Goblet of Fire')
        ..orWhere((w) => w.authorId.equals(int.parse(jkRowling.id)));
      print(query.compile(Set()));

      var books = await query.get(executor);
      expect(books, hasLength(1));

      var book = books.first;
      print(book.toJson());
      expect(book.id, deathlyHallows.id);
      expect(book.name, deathlyHallows.name);

      var author = book.author;
      print(author.toJson());
      expect(author.id, jkRowling.id);
      expect(author.name, jkRowling.name);
    });

    test('union', () async {
      var query1 = new BookQuery()..where.name.like('Deathly%');
      var query2 = new BookQuery()..where.authorId.equals(-1);
      var query3 = new BookQuery()
        ..where.name.isIn(['Goblet of Fire', 'Order of the Phoenix']);
      query1
        ..union(query2)
        ..unionAll(query3);
      print(query1.compile(Set()));

      var books = await query1.get(executor);
      expect(books, hasLength(1));

      var book = books.first;
      print(book.toJson());
      expect(book.id, deathlyHallows.id);
      expect(book.name, deathlyHallows.name);

      var author = book.author;
      print(author.toJson());
      expect(author.id, jkRowling.id);
      expect(author.name, jkRowling.name);
    });

    test('order by', () async {
      var query = AuthorQuery()..orderBy(AuthorFields.name, descending: true);
      var authors = await query.get(executor);
      expect(authors, [jkRowling, jameson]);
    });
  });

  test('insert sets relationship', () {
    expect(deathlyHallows.author, jkRowling);
    //expect(deathlyHallows.author, isNotNull);
    //expect(deathlyHallows.author.name, rowling.name);
  });

  test('delete stream', () async {
    var query = new BookQuery()..where.name.equals(deathlyHallows.name);
    print(query.compile(Set()));
    var books = await query.delete(executor);
    expect(books, hasLength(1));

    var book = books.first;
    expect(book.id, deathlyHallows.id);
    expect(book.author, isNotNull);
    expect((book.author).name, jkRowling.name);
  });

  test('update book', () async {
    var cloned = deathlyHallows.copyWith(name: "Sorcerer's Stone");
    var query = new BookQuery()
      ..where.id.equals(int.parse(cloned.id))
      ..values.copyFrom(cloned);
    var book = await query.updateOne(executor);
    print(book.toJson());
    expect(book.name, cloned.name);
    expect(book.author, isNotNull);
    expect(book.author.name, jkRowling.name);
  });
}
