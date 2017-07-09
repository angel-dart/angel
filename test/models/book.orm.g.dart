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
    var compiled = other.where.toWhereClause(keyword: false);
    if (compiled != null) {
      _and.add(compiled);
    }
  }

  void or(BookQuery other) {
    var compiled = other.where.toWhereClause(keyword: false);
    if (compiled != null) {
      _or.add(compiled);
    }
  }

  void not(BookQuery other) {
    var compiled = other.where.toWhereClause(keyword: false);
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
    if (_and.isNotEmpty) {
      buf.write(' AND (' + _and.join(',') + ')');
    }
    if (_or.isNotEmpty) {
      buf.write(' OR (' + _or.join(',') + ')');
    }
    if (_not.isNotEmpty) {
      buf.write(' NOT (' + _not.join(',') + ')');
    }
    buf.write(';');
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
        buf.toString() +
            ' RETURNING ("id", "name", "created_at", "updated_at");',
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

  Stream<Book> delete(PostgreSQLConnection connection) async {}

  static Future<Book> deleteOne(int id, PostgreSQLConnection connection) async {
    var __ormBeforeDelete__ = await BookQuery.getOne(id, connection);
    var result = await connection.execute('DELETE FROM "books" WHERE id = @id;',
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
    var nRows = await connection.execute(
        'INSERT INTO "books" ("name", "created_at", "updated_at") VALUES (@name, @createdAt, @updatedAt);',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    if (nRows < 1) {
      throw new StateError('Insertion into "books" table failed.');
    }
    var currVal = await connection.query(
        'SELECT * FROM "books" WHERE id = currval(pg_get_serial_sequence(\'books\', \'id\'));');
    return parseRow(currVal[0]);
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
