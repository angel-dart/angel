// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresServiceGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:postgres/postgres.dart';
import 'user.dart';
import 'user.orm.g.dart';

class UserService extends Service {
  final PostgreSQLConnection connection;

  final bool allowRemoveAll;

  final bool allowQuery;

  UserService(this.connection,
      {this.allowRemoveAll: false, this.allowQuery: false});

  UserQuery buildQuery(Map params) {
    var query = new UserQuery();
    if (params['query'] is Map) {
      query.where.id.equals(params['query']['id']);
      query.where.username.equals(params['query']['username']);
      query.where.password.equals(params['query']['password']);
      query.where.email.equals(params['query']['email']);
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

  User applyData(data) {
    if (data is User || data == null) {
      return data;
    }
    if (data is Map) {
      var query = new User();
      if (data.containsKey('username')) {
        query.username = data['username'];
      }
      if (data.containsKey('password')) {
        query.password = data['password'];
      }
      if (data.containsKey('email')) {
        query.email = data['email'];
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

  Future<List<User>> index([Map params]) {
    return buildQuery(params).get(connection).toList();
  }

  Future<User> create(data, [Map params]) {
    return UserQuery.insertUser(connection, applyData(data));
  }

  Future<User> read(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.get(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<User> remove(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.delete(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<User> update(id, data, [Map params]) {
    return UserQuery.updateUser(connection, applyData(data));
  }

  Future<User> modify(id, data, [Map params]) async {
    var query = await read(toId(id), params);
    if (data is User) {
      query = data;
    }
    if (data is Map) {
      if (data.containsKey('username')) {
        query.username = data['username'];
      }
      if (data.containsKey('password')) {
        query.password = data['password'];
      }
      if (data.containsKey('email')) {
        query.email = data['email'];
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
    return await UserQuery.updateUser(connection, query);
  }
}
