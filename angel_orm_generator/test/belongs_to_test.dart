/// Tests for @belongsTo...
library angel_orm_generator.test.book_test;

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'models/author.dart';
import 'models/author.orm.g.dart';
import 'models/book.dart';
import 'models/book.orm.g.dart';
import 'common.dart';

main() {
  PostgreSQLConnection connection;
  Author rowling;
  Book deathlyHallows;

  setUp(() async {
    connection = await connectToPostgres();

    // Insert an author
    rowling = await AuthorQuery.insert(connection, name: 'J.K. Rowling');

    // And a book
    deathlyHallows = await BookQuery.insert(connection,
        authorId: int.parse(rowling.id), name: 'Deathly Hallows');
  });

  tearDown(() => connection.close());

  group('selects', ()
  {
    test('select all', () async {
      var query = new BookQuery();
      var books = await query.get(connection).toList();
      expect(books, hasLength(1));

      var book = books.first;
      print(book.toJson());
      expect(book.id, deathlyHallows.id);
      expect(book.name, deathlyHallows.name);

      var author = book.author as Author;
      print(author.toJson());
      expect(author.id, rowling.id);
      expect(author.name, rowling.name);
    });

    test('select one', () async {
      var query = new BookQuery();
      query.where.id.equals(int.parse(deathlyHallows.id));
      print(query.toSql());

      var book = await BookQuery.getOne(
          int.parse(deathlyHallows.id), connection);
      print(book.toJson());
      expect(book.id, deathlyHallows.id);
      expect(book.name, deathlyHallows.name);

      var author = book.author as Author;
      print(author.toJson());
      expect(author.id, rowling.id);
      expect(author.name, rowling.name);
    });

    test('where clause', () async {
      var query = new BookQuery()
        ..where.name.equals('Goblet of Fire')
        ..or(new BookQueryWhere()..authorId.equals(int.parse(rowling.id)));
      print(query.toSql());

      var books = await query.get(connection).toList();
      expect(books, hasLength(1));

      var book = books.first;
      print(book.toJson());
      expect(book.id, deathlyHallows.id);
      expect(book.name, deathlyHallows.name);

      var author = book.author as Author;
      print(author.toJson());
      expect(author.id, rowling.id);
      expect(author.name, rowling.name);
    });

    test('union', () async {
      var query1 = new BookQuery()
        ..where.name.like('Deathly%');
      var query2 = new BookQuery()
        ..where.authorId.equals(-1);
      var query3 = new BookQuery()
        ..where.name.isIn(['Goblet of Fire', 'Order of the Phoenix']);
      query1
        ..union(query2)
        ..unionAll(query3);
      print(query1.toSql());

      var books = await query1.get(connection).toList();
      expect(books, hasLength(1));

      var book = books.first;
      print(book.toJson());
      expect(book.id, deathlyHallows.id);
      expect(book.name, deathlyHallows.name);

      var author = book.author as Author;
      print(author.toJson());
      expect(author.id, rowling.id);
      expect(author.name, rowling.name);
    });
  });

  test('insert sets relationship', () {
    expect(deathlyHallows.author, isNotNull);
    expect((deathlyHallows.author as Author).name, rowling.name);
  });

  test('delete stream', () async {
    var query = new BookQuery()..where.name.equals(deathlyHallows.name);
    print(query.toSql());
    var books = await query.delete(connection).toList();
    expect(books, hasLength(1));

    var book = books.first;
    expect(book.id, deathlyHallows.id);
    expect(book.author, isNotNull);
    expect((book.author as Author).name, rowling.name);
  });

  test('update book', () async {
    var cloned = deathlyHallows.clone()..name = 'Sorcerer\'s Stone';
    var book = await BookQuery.updateBook(connection, cloned);
    print(book.toJson());
    expect(book.name, cloned.name);
    expect(book.author, isNotNull);
    expect((book.author as Author).name, rowling.name);
  });
}
