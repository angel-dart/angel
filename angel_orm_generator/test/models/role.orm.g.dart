// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresOrmGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'role.dart';

class RoleQuery {
  final Map<RoleQuery, bool> _unions = {};

  String _sortKey;

  String _sortMode;

  int limit;

  int offset;

  final List<RoleQueryWhere> _or = [];

  final RoleQueryWhere where = new RoleQueryWhere();

  void union(RoleQuery query) {
    _unions[query] = false;
  }

  void unionAll(RoleQuery query) {
    _unions[query] = true;
  }

  void sortDescending(String key) {
    _sortMode = 'Descending';
    _sortKey = ('' + key);
  }

  void sortAscending(String key) {
    _sortMode = 'Ascending';
    _sortKey = ('' + key);
  }

  void or(RoleQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null
        ? prefix
        : 'SELECT id, name, created_at, updated_at FROM "roles"');
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

  static Role parseRow(List row) {
    var result = new Role.fromJson({
      'id': row[0].toString(),
      'name': row[1],
      'created_at': row[2],
      'updated_at': row[3]
    });
    return result;
  }

  Stream<Role> get(PostgreSQLConnection connection) {
    StreamController<Role> ctrl = new StreamController<Role>();
    connection.query(toSql()).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Role> getOne(int id, PostgreSQLConnection connection) {
    var query = new RoleQuery();
    query.where.id.equals(id);
    return query.get(connection).first.catchError((_) => null);
  }

  Stream<Role> update(PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "roles" SET ("name", "created_at", "updated_at") = (@name, CAST (@createdAt AS timestamp), CAST (@updatedAt AS timestamp)) ');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<Role>();
    connection.query(
        buf.toString() + ' RETURNING "id", "name", "created_at", "updated_at";',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        }).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  Stream<Role> delete(PostgreSQLConnection connection) {
    StreamController<Role> ctrl = new StreamController<Role>();
    connection
        .query(toSql('DELETE FROM "roles"') +
            ' RETURNING "id", "name", "created_at", "updated_at";')
        .then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Role> deleteOne(int id, PostgreSQLConnection connection) {
    var query = new RoleQuery();
    query.where.id.equals(id);
    return query.delete(connection).first;
  }

  static Future<Role> insert(PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "roles" ("name", "created_at", "updated_at") VALUES (@name, CAST (@createdAt AS timestamp), CAST (@updatedAt AS timestamp)) RETURNING "id", "name", "created_at", "updated_at";',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    var output = parseRow(result[0]);
    return output;
  }

  static Future<Role> insertRole(PostgreSQLConnection connection, Role role) {
    return RoleQuery.insert(connection,
        name: role.name, createdAt: role.createdAt, updatedAt: role.updatedAt);
  }

  static Future<Role> updateRole(PostgreSQLConnection connection, Role role) {
    var query = new RoleQuery();
    query.where.id.equals(int.parse(role.id));
    return query
        .update(connection,
            name: role.name,
            createdAt: role.createdAt,
            updatedAt: role.updatedAt)
        .first;
  }

  static Stream<Role> getAll(PostgreSQLConnection connection) =>
      new RoleQuery().get(connection);
}

class RoleQueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>();

  final StringSqlExpressionBuilder name = new StringSqlExpressionBuilder();

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('roles.created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('roles.updated_at');

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('roles.id ' + id.compile());
    }
    if (name.hasValue) {
      expressions.add('roles.name ' + name.compile());
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

class RoleFields {
  static const id = 'id';

  static const name = 'name';

  static const createdAt = 'created_at';

  static const updatedAt = 'updated_at';
}
