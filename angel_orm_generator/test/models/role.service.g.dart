// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresServiceGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:postgres/postgres.dart';
import 'role.dart';
import 'role.orm.g.dart';

class RoleService extends Service {
  final PostgreSQLConnection connection;

  final bool allowRemoveAll;

  final bool allowQuery;

  RoleService(this.connection,
      {this.allowRemoveAll: false, this.allowQuery: false});

  RoleQuery buildQuery(Map params) {
    var query = new RoleQuery();
    if (params['query'] is Map) {
      query.where.id.equals(params['query']['id']);
      query.where.name.equals(params['query']['name']);
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

  Role applyData(data) {
    if (data is Role || data == null) {
      return data;
    }
    if (data is Map) {
      var query = new Role();
      if (data.containsKey('name')) {
        query.name = data['name'];
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

  Future<List<Role>> index([Map params]) {
    return buildQuery(params).get(connection).toList();
  }

  Future<Role> create(data, [Map params]) {
    return RoleQuery.insertRole(connection, applyData(data));
  }

  Future<Role> read(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.get(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<Role> remove(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.delete(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<Role> update(id, data, [Map params]) {
    return RoleQuery.updateRole(connection, applyData(data));
  }

  Future<Role> modify(id, data, [Map params]) async {
    var query = await read(toId(id), params);
    if (data is Role) {
      query = data;
    }
    if (data is Map) {
      if (data.containsKey('name')) {
        query.name = data['name'];
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
    return await RoleQuery.updateRole(connection, query);
  }
}
