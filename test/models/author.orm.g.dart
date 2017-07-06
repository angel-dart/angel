// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresORMGenerator
// Target: class _Author
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'author.dart';

class AuthorQuery {
  final List<String> _and = [];

  final List<String> _or = [];

  final List<String> _not = [];

  final AuthorQueryWhere where = new AuthorQueryWhere();

  void and(AuthorQuery other) {
    var compiled = other.where.toWhereClause();
    if (compiled != null) {
      _and.add(compiled);
    }
  }

  void or(AuthorQuery other) {
    var compiled = other.where.toWhereClause();
    if (compiled != null) {
      _or.add(compiled);
    }
  }

  void not(AuthorQuery other) {
    var compiled = other.where.toWhereClause();
    if (compiled != null) {
      _not.add(compiled);
    }
  }

  String toSql() {
    var buf = new StringBuffer('SELECT * FROM "authors"');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(' ' + whereClause);
    }
    buf.write(';');
    return buf.toString();
  }

  static Author parseRow(List row) {
    return new Author.fromJson({
      'id': row[0].toString(),
      'name': row[1],
      'created_at': DATE_YMD_HMS.parse(row[2]),
      'updated_at': DATE_YMD_HMS.parse(row[3])
    });
  }

  Stream<Author> get(PostgreSQLConnection connection) {
    StreamController<Author> ctrl = new StreamController<Author>();
    connection.query(toSql()).then((rows) {
      rows.map(parseRow).forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Author> getOne(int id, PostgreSQLConnection connection) {
    return connection.query('SELECT * FROM "authors" WHERE "id" = @id;',
        substitutionValues: {'id': id}).then((rows) => parseRow(rows.first));
  }

  Future<Author> update(int id, PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'UPDATE "authors" SET ("name", "created_at", "updated_at") = (@name, @createdAt, @updatedAt) WHERE "id" = @id RETURNING ("id", "name", "created_at", "updated_at");',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__,
          'id': id
        });
    return parseRow(result);
  }

  Future<Author> delete(int id, PostgreSQLConnection connection) async {
    var __ormBeforeDelete__ = await AuthorQuery.getOne(id, connection);
    var result = await connection.execute(
        'DELETE FROM "authors" WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': id});
    if (result != 1) {
      new StateError('DELETE query deleted ' +
          result +
          ' row(s), instead of exactly 1 row.');
    }
    return __ormBeforeDelete__;
  }

  static Future<Author> insert(PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "authors" ("name", "created_at", "updated_at") VALUES (@name, @createdAt, @updatedAt) RETURNING ("id", "name", "created_at", "updated_at");',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    return parseRow(result);
  }

  static Stream<Author> getAll(PostgreSQLConnection connection) =>
      new AuthorQuery().get(connection);
}

class AuthorQueryWhere {
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
