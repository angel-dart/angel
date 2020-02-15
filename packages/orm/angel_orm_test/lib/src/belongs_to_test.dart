import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';
import 'models/book.dart';
import 'util.dart';

belongsToTests(FutureOr<QueryExecutor> Function() createExecutor,
    {FutureOr<void> Function(QueryExecutor) close}) {
  QueryExecutor executor;
  Author jkRowling;
  Author jameson;
  Book deathlyHallows;
  close ??= (_) => null;

  setUp(() async {
    executor = await createExecutor();

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

  tearDown(() => close(executor));

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
      print(AuthorSerializer.toMap(author));
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
      print(AuthorSerializer.toMap(author));
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
      print(AuthorSerializer.toMap(author));
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
      print(AuthorSerializer.toMap(author));
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
    printSeparator('Delete stream test');
    var query = new BookQuery()..where.name.equals(deathlyHallows.name);
    print(query.compile(Set(), preamble: 'DELETE', withFields: false));
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

  group('joined subquery', () {
    // To verify that the joined subquery is correct,
    // we test both a query that return empty, and one
    // that should return correctly.
    test('returns empty on false subquery', () async {
      printSeparator('False subquery test');
      var query = BookQuery()..author.where.name.equals('Billie Jean');
      expect(await query.get(executor), isEmpty);
    });

    test('returns values on true subquery', () async {
      printSeparator('True subquery test');
      var query = BookQuery()..author.where.name.like('%Rowling%');
      expect(await query.get(executor), [deathlyHallows]);
    });
  });
}
