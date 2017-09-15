// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresServiceGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:postgres/postgres.dart';
import 'foot.dart';
import 'foot.orm.g.dart';

class FootService extends Service {
  final PostgreSQLConnection connection;

  final bool allowRemoveAll;

  final bool allowQuery;

  FootService(this.connection,
      {this.allowRemoveAll: false, this.allowQuery: false});

  FootQuery buildQuery(Map params) {
    var query = new FootQuery();
    if (params['query'] is Map) {
      query.where.id.equals(params['query']['id']);
      query.where.legId.equals(params['query']['leg_id']);
      query.where.nToes.equals(params['query']['n_toes']);
      query.where.createdAt.equals(params['query']['created_at'] is String
          ? DateTime.parse(params['query']['created_at'])
          : params['query']['created_at'] != null
              ? params['query']['created_at'] is String
                  ? DateTime.parse(params['query']['created_at'])
                  : params['query']['created_at']
              : new DateTime.now());
      query.where.updatedAt.equals(params['query']['updated_at'] is String
          ? DateTime.parse(params['query']['updated_at'])
          : params['query']['updated_at'] != null
              ? params['query']['updated_at'] is String
                  ? DateTime.parse(params['query']['updated_at'])
                  : params['query']['updated_at']
              : new DateTime.now());
    }
    return query;
  }

  int toId(id) {
    if (id is int) {
      return id;
    } else {
      if (id == 'null' || id == null) {
        return null;
      } else {
        return int.parse(id.toString());
      }
    }
  }

  Foot applyData(data) {
    if (data is Foot || data == null) {
      return data;
    }
    if (data is Map) {
      var query = new Foot();
      if (data.containsKey('leg_id')) {
        query.legId = data['leg_id'];
      }
      if (data.containsKey('n_toes')) {
        query.nToes = data['n_toes'];
      }
      if (data.containsKey('created_at')) {
        query.createdAt = data['created_at'] is String
            ? DateTime.parse(data['created_at'])
            : data['created_at'] != null
                ? data['created_at'] is String
                    ? DateTime.parse(data['created_at'])
                    : data['created_at']
                : new DateTime.now();
      }
      if (data.containsKey('updated_at')) {
        query.updatedAt = data['updated_at'] is String
            ? DateTime.parse(data['updated_at'])
            : data['updated_at'] != null
                ? data['updated_at'] is String
                    ? DateTime.parse(data['updated_at'])
                    : data['updated_at']
                : new DateTime.now();
      }
      return query;
    } else
      throw new AngelHttpException.badRequest(message: 'Invalid data.');
  }

  Future<List<Foot>> index([Map params]) {
    return buildQuery(params).get(connection).toList();
  }

  Future<Foot> create(data, [Map params]) {
    return FootQuery.insertFoot(connection, applyData(data));
  }

  Future<Foot> read(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.get(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<Foot> remove(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.delete(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<Foot> update(id, data, [Map params]) {
    return FootQuery.updateFoot(connection, applyData(data));
  }

  Future<Foot> modify(id, data, [Map params]) async {
    var query = await read(toId(id), params);
    if (data is Foot) {
      query = data;
    }
    if (data is Map) {
      if (data.containsKey('leg_id')) {
        query.legId = data['leg_id'];
      }
      if (data.containsKey('n_toes')) {
        query.nToes = data['n_toes'];
      }
      if (data.containsKey('created_at')) {
        query.createdAt = data['created_at'] is String
            ? DateTime.parse(data['created_at'])
            : data['created_at'] != null
                ? data['created_at'] is String
                    ? DateTime.parse(data['created_at'])
                    : data['created_at']
                : new DateTime.now();
      }
      if (data.containsKey('updated_at')) {
        query.updatedAt = data['updated_at'] is String
            ? DateTime.parse(data['updated_at'])
            : data['updated_at'] != null
                ? data['updated_at'] is String
                    ? DateTime.parse(data['updated_at'])
                    : data['updated_at']
                : new DateTime.now();
      }
    }
    return await FootQuery.updateFoot(connection, query);
  }
}
