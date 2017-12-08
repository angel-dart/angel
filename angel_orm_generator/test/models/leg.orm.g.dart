// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresOrmGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'leg.dart';
import 'foot.orm.g.dart';

class LegQuery {
  final Map<LegQuery, bool> _unions = {};

  String _sortKey;

  String _sortMode;

  int limit;

  int offset;

  final List<LegQueryWhere> _or = [];

  final LegQueryWhere where = new LegQueryWhere();

  void union(LegQuery query) {
    _unions[query] = false;
  }

  void unionAll(LegQuery query) {
    _unions[query] = true;
  }

  void sortDescending(String key) {
    _sortMode = 'Descending';
    _sortKey = ('legs.' + key);
  }

  void sortAscending(String key) {
    _sortMode = 'Ascending';
    _sortKey = ('legs.' + key);
  }

  void or(LegQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null
        ? prefix
        : 'SELECT legs.id, legs.name, legs.created_at, legs.updated_at, foots.id, foots.leg_id, foots.n_toes, foots.created_at, foots.updated_at FROM "legs"');
    if (prefix == null) {
      buf.write(' LEFT OUTER JOIN foots ON legs.id = foots.leg_id');
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

  static Leg parseRow(List row) {
    var result = new Leg.fromJson({
      'id': row[0].toString(),
      'name': row[1],
      'created_at': row[2],
      'updated_at': row[3]
    });
    if (row.length > 4) {
      result.foot =
          FootQuery.parseRow([row[4], row[5], row[6], row[7], row[8]]);
    }
    return result;
  }

  Stream<Leg> get(PostgreSQLConnection connection) {
    StreamController<Leg> ctrl = new StreamController<Leg>();
    connection.query(toSql()).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        var footQuery = new FootQuery();
        footQuery.where.id.equals(row[0]);
        parsed.foot =
            await footQuery.get(connection).first.catchError((_) => null);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Leg> getOne(int id, PostgreSQLConnection connection) {
    var query = new LegQuery();
    query.where.id.equals(id);
    return query.get(connection).first.catchError((_) => null);
  }

  Stream<Leg> update(PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "legs" SET ("name", "created_at", "updated_at") = (@name, CAST (@createdAt AS timestamp), CAST (@updatedAt AS timestamp)) ');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<Leg>();
    connection.query(
        buf.toString() + ' RETURNING "id", "name", "created_at", "updated_at";',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        }).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        var footQuery = new FootQuery();
        footQuery.where.id.equals(row[0]);
        parsed.foot =
            await footQuery.get(connection).first.catchError((_) => null);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  Stream<Leg> delete(PostgreSQLConnection connection) {
    StreamController<Leg> ctrl = new StreamController<Leg>();
    connection
        .query(toSql('DELETE FROM "legs"') +
            ' RETURNING "id", "name", "created_at", "updated_at";')
        .then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        var footQuery = new FootQuery();
        footQuery.where.id.equals(row[0]);
        parsed.foot =
            await footQuery.get(connection).first.catchError((_) => null);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Leg> deleteOne(int id, PostgreSQLConnection connection) {
    var query = new LegQuery();
    query.where.id.equals(id);
    return query.delete(connection).first;
  }

  static Future<Leg> insert(PostgreSQLConnection connection,
      {String name, DateTime createdAt, DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "legs" ("name", "created_at", "updated_at") VALUES (@name, CAST (@createdAt AS timestamp), CAST (@updatedAt AS timestamp)) RETURNING "id", "name", "created_at", "updated_at";',
        substitutionValues: {
          'name': name,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    var output = parseRow(result[0]);
    var footQuery = new FootQuery();
    footQuery.where.id.equals(result[0][0]);
    output.foot = await footQuery.get(connection).first.catchError((_) => null);
    return output;
  }

  static Future<Leg> insertLeg(PostgreSQLConnection connection, Leg leg) {
    return LegQuery.insert(connection,
        name: leg.name, createdAt: leg.createdAt, updatedAt: leg.updatedAt);
  }

  static Future<Leg> updateLeg(PostgreSQLConnection connection, Leg leg) {
    var query = new LegQuery();
    query.where.id.equals(int.parse(leg.id));
    return query
        .update(connection,
            name: leg.name, createdAt: leg.createdAt, updatedAt: leg.updatedAt)
        .first;
  }

  static Stream<Leg> getAll(PostgreSQLConnection connection) =>
      new LegQuery().get(connection);
}

class LegQueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>();

  final StringSqlExpressionBuilder name = new StringSqlExpressionBuilder();

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('legs.created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('legs.updated_at');

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('legs.id ' + id.compile());
    }
    if (name.hasValue) {
      expressions.add('legs.name ' + name.compile());
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

class LegFields {
  static const id = 'id';

  static const name = 'name';

  static const createdAt = 'created_at';

  static const updatedAt = 'updated_at';
}
