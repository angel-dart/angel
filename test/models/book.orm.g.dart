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
  final List<String> _and = [];

  final List<String> _or = [];

  final List<String> _not = [];

  final BookQueryWhere where = new BookQueryWhere();

  void and(BookQuery other) {
    var compiled = other.where.toWhereClause();
    if (compiled != null) {
      _and.add(compiled);
    }
  }

  void or(BookQuery other) {
    var compiled = other.where.toWhereClause();
    if (compiled != null) {
      _or.add(compiled);
    }
  }

  void not(BookQuery other) {
    var compiled = other.where.toWhereClause();
    if (compiled != null) {
      _not.add(compiled);
    }
  }

  String toSql() {
    var buf = new StringBuffer('SELECT * FROM "books"');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(' ' + whereClause);
    }
    buf.write(';');
    return buf.toString();
  }

  static Book parseRow(List row) {
    return new Book.fromJson({
      'id': row[0].toString(),
      'name': row[1],
      'created_at': DATE_YMD_HMS.parse(row[2]),
      'updated_at': DATE_YMD_HMS.parse(row[3]),
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

  Future<Book> update(int id, PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'UPDATE "books" SET ("name", "created_at", "updated_at") = (@name, @createdAt, @updatedAt) WHERE "id" = @id RETURNING ("id", "name", "created_at", "updated_at");',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__,
          'id': id
        });
    return parseRow(result);
  }

  Future<Book> delete(int id, PostgreSQLConnection connection) async {
    var __ormBeforeDelete__ = await BookQuery.getOne(id, connection);
    var result = await connection.execute(
        'DELETE FROM "books" WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': id});
    if (result != 1) {
      new StateError('DELETE query deleted ' +
          result +
          ' row(s), instead of exactly 1 row.');
    }
    return __ormBeforeDelete__;
  }

  static Future<Book> insert(PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "books" ("name", "created_at", "updated_at") VALUES (@name, @createdAt, @updatedAt) RETURNING ("id", "name", "created_at", "updated_at");',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    return parseRow(result);
  }

  static Stream<Book> getAll(PostgreSQLConnection connection) =>
      new BookQuery().get(connection);
}

class BookQueryWhere {
  final StringSqlExpressionBuilder id = new StringSqlExpressionBuilder();

  final StringSqlExpressionBuilder name = new StringSqlExpressionBuilder();

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  String toWhereClause() {
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
    return expressions.isEmpty ? null : ('WHERE ' + expressions.join(' AND '));
  }
}
