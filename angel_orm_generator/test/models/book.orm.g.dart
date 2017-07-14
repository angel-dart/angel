// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresORMGenerator
// Target: class _Book
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
    _sortKey = key;
  }

  void sortAscending(String key) {
    _sortMode = 'Ascending';
    _sortKey = key;
  }

  void or(BookQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null ? prefix : 'SELECT * FROM "books"');
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
    return new Book.fromJson({
      'id': row[0].toString(),
      'name': row[1],
      'created_at': row[2],
      'updated_at': row[3],
      'author': row.length < 5 ? null : AuthorQuery.parseRow(row[4])
    });
  }

  Stream<Book> get(PostgreSQLConnection connection) {
    StreamController<Book> ctrl = new StreamController<Book>();
    connection.query(toSql()).then((rows) {
      rows.map(parseRow).forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Book> getOne(int id, PostgreSQLConnection connection) {
    return connection.query('SELECT * FROM "books" WHERE "id" = @id;',
        substitutionValues: {'id': id}).then((rows) => parseRow(rows.first));
  }

  Stream<Book> update(PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "books" SET ("name", "created_at", "updated_at") = (@name, @createdAt, @updatedAt) ');
    var whereClause = where.toWhereClause();
    if (whereClause == null) {
      buf.write('WHERE "id" = @id');
    } else {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<Book>();
    connection.query(
        buf.toString() + ' RETURNING "id", "name", "created_at", "updated_at";',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        }).then((rows) {
      rows.map(parseRow).forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  Stream<Book> delete(PostgreSQLConnection connection) {
    StreamController<Book> ctrl = new StreamController<Book>();
    connection
        .query(toSql('DELETE FROM "books"') +
            ' RETURNING "id", "name", "created_at", "updated_at";')
        .then((rows) {
      rows.map(parseRow).forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Book> deleteOne(int id, PostgreSQLConnection connection) async {
    var result = await connection.query(
        'DELETE FROM "books" WHERE id = @id RETURNING "id", "name", "created_at", "updated_at";',
        substitutionValues: {'id': id});
    return parseRow(result[0]);
  }

  static Future<Book> insert(PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "books" ("name", "created_at", "updated_at") VALUES (@name, @createdAt, @updatedAt) RETURNING "id", "name", "created_at", "updated_at";',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    return parseRow(result[0]);
  }

  static Future<Book> insertBook(PostgreSQLConnection connection, Book book) {
    return BookQuery.insert(connection,
        name: book.name, createdAt: book.createdAt, updatedAt: book.updatedAt);
  }

  static Future<Book> updateBook(PostgreSQLConnection connection, Book book) {
    var query = new BookQuery();
    query.where.id.equals(int.parse(book.id));
    return query
        .update(connection,
            name: book.name,
            createdAt: book.createdAt,
            updatedAt: book.updatedAt)
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
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('"id" ' + id.compile());
    }
    if (name.hasValue) {
      expressions.add('"name" ' + name.compile());
    }
    if (createdAt.hasValue) {
      expressions.add(createdAt.compile());
    }
    if (updatedAt.hasValue) {
      expressions.add(updatedAt.compile());
    }
    return expressions.isEmpty
        ? null
        : ((keyword != false ? 'WHERE ' : '') + expressions.join(' AND '));
  }
}
