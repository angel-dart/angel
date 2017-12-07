// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresOrmGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'book.dart';
import 'author.orm.g.dart';

class BookQuery {
  final Map<BookQuery, bool> _unions = {};

  String _sortKey;

  String _sortMode;

  int limit;

  int offset;

  final List<BookQueryWhere> _or = [];

  final BookQueryWhere where = new BookQueryWhere();

  void union(BookQuery query) {
    _unions[query] = false;
  }

  void unionAll(BookQuery query) {
    _unions[query] = true;
  }

  void sortDescending(String key) {
    _sortMode = 'Descending';
    _sortKey = ('books.' + key);
  }

  void sortAscending(String key) {
    _sortMode = 'Ascending';
    _sortKey = ('books.' + key);
  }

  void or(BookQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null
        ? prefix
        : 'SELECT books.id, books.name, books.created_at, books.updated_at, books.author_id, authors.id, authors.name, authors.created_at, authors.updated_at FROM "books"');
    if (prefix == null) {
      buf.write(' LEFT OUTER JOIN authors ON books.author_id = authors.id');
    }
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(' ' + whereClause);
    }
    _or.forEach((x) {
      var whereClause = x.toWhereClause(keyword: false);
      if (whereClause != null) {
        buf.write(' OR (' + whereClause + ')');
      }
    });
    if (prefix == null) {
      if (limit != null) {
        buf.write(' LIMIT ' + limit.toString());
      }
      if (offset != null) {
        buf.write(' OFFSET ' + offset.toString());
      }
      if (_sortMode == 'Descending') {
        buf.write(' ORDER BY "' + _sortKey + '" DESC');
      }
      if (_sortMode == 'Ascending') {
        buf.write(' ORDER BY "' + _sortKey + '" ASC');
      }
      _unions.forEach((query, all) {
        buf.write(' UNION');
        if (all) {
          buf.write(' ALL');
        }
        buf.write(' (');
        var sql = query.toSql().replaceAll(';', '');
        buf.write(sql + ')');
      });
      buf.write(';');
    }
    return buf.toString();
  }

  static Book parseRow(List row) {
    var result = new Book.fromJson({
      'id': row[0].toString(),
      'name': row[1],
      'created_at': row[2],
      'updated_at': row[3],
      'author_id': row[4]
    });
    if (row.length > 5) {
      result.author = AuthorQuery.parseRow([row[5], row[6], row[7], row[8]]);
    }
    return result;
  }

  Stream<Book> get(PostgreSQLConnection connection) {
    StreamController<Book> ctrl = new StreamController<Book>();
    connection.query(toSql()).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        parsed.author = await AuthorQuery.getOne(row[4], connection);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Book> getOne(int id, PostgreSQLConnection connection) {
    var query = new BookQuery();
    query.where.id.equals(id);
    return query.get(connection).first.catchError((_) => null);
  }

  Stream<Book> update(PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt, int authorId}) {
    var buf = new StringBuffer(
        'UPDATE "books" SET ("name", "created_at", "updated_at", "author_id") = (@name, @createdAt, @updatedAt, @authorId) ');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<Book>();
    connection.query(
        buf.toString() +
            ' RETURNING "id", "name", "created_at", "updated_at", "author_id";',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__,
          'authorId': authorId
        }).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        parsed.author = await AuthorQuery.getOne(row[4], connection);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  Stream<Book> delete(PostgreSQLConnection connection) {
    StreamController<Book> ctrl = new StreamController<Book>();
    connection
        .query(toSql('DELETE FROM "books"') +
            ' RETURNING "id", "name", "created_at", "updated_at", "author_id";')
        .then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        parsed.author = await AuthorQuery.getOne(row[4], connection);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Book> deleteOne(int id, PostgreSQLConnection connection) {
    var query = new BookQuery();
    query.where.id.equals(id);
    return query.delete(connection).first;
  }

  static Future<Book> insert(PostgreSQLConnection connection,
      {String name,
      DateTime createdAt,
      DateTime updatedAt,
      int authorId}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "books" ("name", "created_at", "updated_at", "author_id") VALUES (@name, @createdAt, @updatedAt, @authorId) RETURNING "id", "name", "created_at", "updated_at", "author_id";',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__,
          'authorId': authorId
        });
    var output = parseRow(result[0]);
    output.author = await AuthorQuery.getOne(result[0][4], connection);
    return output;
  }

  static Future<Book> insertBook(PostgreSQLConnection connection, Book book,
      {int authorId}) {
    return BookQuery.insert(connection,
        name: book.name,
        createdAt: book.createdAt,
        updatedAt: book.updatedAt,
        authorId: authorId);
  }

  static Future<Book> updateBook(PostgreSQLConnection connection, Book book) {
    var query = new BookQuery();
    query.where.id.equals(int.parse(book.id));
    return query
        .update(connection,
            name: book.name,
            createdAt: book.createdAt,
            updatedAt: book.updatedAt,
            authorId: int.parse(book.author.id))
        .first;
  }

  static Stream<Book> getAll(PostgreSQLConnection connection) =>
      new BookQuery().get(connection);
}

class BookQueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>();

  final StringSqlExpressionBuilder name = new StringSqlExpressionBuilder();

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('books.created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('books.updated_at');

  final NumericSqlExpressionBuilder<int> authorId =
      new NumericSqlExpressionBuilder<int>();

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('books.id ' + id.compile());
    }
    if (name.hasValue) {
      expressions.add('books.name ' + name.compile());
    }
    if (createdAt.hasValue) {
      expressions.add(createdAt.compile());
    }
    if (updatedAt.hasValue) {
      expressions.add(updatedAt.compile());
    }
    if (authorId.hasValue) {
      expressions.add('books.author_id ' + authorId.compile());
    }
    return expressions.isEmpty
        ? null
        : ((keyword != false ? 'WHERE ' : '') + expressions.join(' AND '));
  }
}

class BookFields {
  static const id = 'id';

  static const name = 'name';

  static const createdAt = 'created_at';

  static const updatedAt = 'updated_at';

  static const authorId = 'author_id';
}
