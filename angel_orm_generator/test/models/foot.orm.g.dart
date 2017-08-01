// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresORMGenerator
// Target: class _Foot
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'foot.dart';

class FootQuery {
  final Map<FootQuery, bool> _unions = {};

  String _sortKey;

  String _sortMode;

  int limit;

  int offset;

  final List<FootQueryWhere> _or = [];

  final FootQueryWhere where = new FootQueryWhere();

  void union(FootQuery query) {
    _unions[query] = false;
  }

  void unionAll(FootQuery query) {
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

  void or(FootQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null
        ? prefix
        : 'SELECT id, leg_id, n_toes, created_at, updated_at FROM "foots"');
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

  static Foot parseRow(List row) {
    var result = new Foot.fromJson({
      'id': row[0].toString(),
      'leg_id': row[1],
      'n_toes': row[2],
      'created_at': row[3],
      'updated_at': row[4]
    });
    return result;
  }

  Stream<Foot> get(PostgreSQLConnection connection) {
    StreamController<Foot> ctrl = new StreamController<Foot>();
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

  static Future<Foot> getOne(int id, PostgreSQLConnection connection) {
    var query = new FootQuery();
    query.where.id.equals(id);
    return query.get(connection).first.catchError((_) => null);
  }

  Stream<Foot> update(PostgreSQLConnection connection,
      {int legId, int nToes, DateTime createdAt, DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "foots" SET ("leg_id", "n_toes", "created_at", "updated_at") = (@legId, @nToes, @createdAt, @updatedAt) ');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<Foot>();
    connection.query(
        buf.toString() +
            ' RETURNING "id", "leg_id", "n_toes", "created_at", "updated_at";',
        substitutionValues: {
          'legId': legId,
          'nToes': nToes,
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

  Stream<Foot> delete(PostgreSQLConnection connection) {
    StreamController<Foot> ctrl = new StreamController<Foot>();
    connection
        .query(toSql('DELETE FROM "foots"') +
            ' RETURNING "id", "leg_id", "n_toes", "created_at", "updated_at";')
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

  static Future<Foot> deleteOne(int id, PostgreSQLConnection connection) {
    var query = new FootQuery();
    query.where.id.equals(id);
    return query.delete(connection).first;
  }

  static Future<Foot> insert(PostgreSQLConnection connection,
      {int legId, int nToes, DateTime createdAt, DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "foots" ("leg_id", "n_toes", "created_at", "updated_at") VALUES (@legId, @nToes, @createdAt, @updatedAt) RETURNING "id", "leg_id", "n_toes", "created_at", "updated_at";',
        substitutionValues: {
          'legId': legId,
          'nToes': nToes,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    var output = parseRow(result[0]);
    return output;
  }

  static Future<Foot> insertFoot(PostgreSQLConnection connection, Foot foot) {
    return FootQuery.insert(connection,
        legId: foot.legId,
        nToes: foot.nToes,
        createdAt: foot.createdAt,
        updatedAt: foot.updatedAt);
  }

  static Future<Foot> updateFoot(PostgreSQLConnection connection, Foot foot) {
    var query = new FootQuery();
    query.where.id.equals(int.parse(foot.id));
    return query
        .update(connection,
            legId: foot.legId,
            nToes: foot.nToes,
            createdAt: foot.createdAt,
            updatedAt: foot.updatedAt)
        .first;
  }

  static Stream<Foot> getAll(PostgreSQLConnection connection) =>
      new FootQuery().get(connection);
}

class FootQueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>();

  final NumericSqlExpressionBuilder<int> legId =
      new NumericSqlExpressionBuilder<int>();

  final NumericSqlExpressionBuilder<int> nToes =
      new NumericSqlExpressionBuilder<int>();

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('foots.created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('foots.updated_at');

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('foots.id ' + id.compile());
    }
    if (legId.hasValue) {
      expressions.add('foots.leg_id ' + legId.compile());
    }
    if (nToes.hasValue) {
      expressions.add('foots.n_toes ' + nToes.compile());
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
