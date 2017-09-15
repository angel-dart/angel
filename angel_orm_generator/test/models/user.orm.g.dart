// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresOrmGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'user.dart';
import 'role.orm.g.dart';

class UserQuery {
  final Map<UserQuery, bool> _unions = {};

  String _sortKey;

  String _sortMode;

  int limit;

  int offset;

  final List<UserQueryWhere> _or = [];

  final UserQueryWhere where = new UserQueryWhere();

  void union(UserQuery query) {
    _unions[query] = false;
  }

  void unionAll(UserQuery query) {
    _unions[query] = true;
  }

  void sortDescending(String key) {
    _sortMode = 'Descending';
    _sortKey = ('users.' + key);
  }

  void sortAscending(String key) {
    _sortMode = 'Ascending';
    _sortKey = ('users.' + key);
  }

  void or(UserQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null
        ? prefix
        : 'SELECT users.id, users.username, users.password, users.email, users.created_at, users.updated_at FROM "users"');
    if (prefix == null) {}
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

  static User parseRow(List row) {
    var result = new User.fromJson({
      'id': row[0].toString(),
      'username': row[1],
      'password': row[2],
      'email': row[3],
      'created_at': row[4],
      'updated_at': row[5]
    });
    if (row.length > 6) {
      result.roles = RoleQuery.parseRow([row[6], row[7], row[8], row[9]]);
    }
    return result;
  }

  Stream<User> get(PostgreSQLConnection connection) {
    StreamController<User> ctrl = new StreamController<User>();
    connection.query(toSql()).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        var roleQuery = new RoleQuery();
        roleQuery.where.id.equals(row[6]);
        parsed.roles.addAll(await roleQuery.get(connection).toList());
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<User> getOne(int id, PostgreSQLConnection connection) {
    var query = new UserQuery();
    query.where.id.equals(id);
    return query.get(connection).first.catchError((_) => null);
  }

  Stream<User> update(PostgreSQLConnection connection,
      {String username,
      String password,
      String email,
      DateTime createdAt,
      DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "users" SET ("username", "password", "email", "created_at", "updated_at") = (@username, @password, @email, @createdAt, @updatedAt) ');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<User>();
    connection.query(
        buf.toString() +
            ' RETURNING "id", "username", "password", "email", "created_at", "updated_at";',
        substitutionValues: {
          'username': username,
          'password': password,
          'email': email,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        }).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        var roleQuery = new RoleQuery();
        roleQuery.where.id.equals(row[6]);
        parsed.roles.addAll(await roleQuery.get(connection).toList());
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  Stream<User> delete(PostgreSQLConnection connection) {
    StreamController<User> ctrl = new StreamController<User>();
    connection
        .query(toSql('DELETE FROM "users"') +
            ' RETURNING "id", "username", "password", "email", "created_at", "updated_at";')
        .then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        var roleQuery = new RoleQuery();
        roleQuery.where.id.equals(row[6]);
        parsed.roles.addAll(await roleQuery.get(connection).toList());
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<User> deleteOne(int id, PostgreSQLConnection connection) {
    var query = new UserQuery();
    query.where.id.equals(id);
    return query.delete(connection).first;
  }

  static Future<User> insert(PostgreSQLConnection connection,
      {String username,
      String password,
      String email,
      DateTime createdAt,
      DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "users" ("username", "password", "email", "created_at", "updated_at") VALUES (@username, @password, @email, @createdAt, @updatedAt) RETURNING "id", "username", "password", "email", "created_at", "updated_at";',
        substitutionValues: {
          'username': username,
          'password': password,
          'email': email,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    var output = parseRow(result[0]);
    var roleQuery = new RoleQuery();
    roleQuery.where.id.equals(result[0][6]);
    output.roles.addAll(await roleQuery.get(connection).toList());
    return output;
  }

  static Future<User> insertUser(PostgreSQLConnection connection, User user,
      {int roleId}) {
    return UserQuery.insert(connection,
        username: user.username,
        password: user.password,
        email: user.email,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt);
  }

  static Future<User> updateUser(PostgreSQLConnection connection, User user) {
    var query = new UserQuery();
    query.where.id.equals(int.parse(user.id));
    return query
        .update(connection,
            username: user.username,
            password: user.password,
            email: user.email,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt)
        .first;
  }

  static Stream<User> getAll(PostgreSQLConnection connection) =>
      new UserQuery().get(connection);
}

class UserQueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>();

  final StringSqlExpressionBuilder username = new StringSqlExpressionBuilder();

  final StringSqlExpressionBuilder password = new StringSqlExpressionBuilder();

  final StringSqlExpressionBuilder email = new StringSqlExpressionBuilder();

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('users.created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('users.updated_at');

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('users.id ' + id.compile());
    }
    if (username.hasValue) {
      expressions.add('users.username ' + username.compile());
    }
    if (password.hasValue) {
      expressions.add('users.password ' + password.compile());
    }
    if (email.hasValue) {
      expressions.add('users.email ' + email.compile());
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
