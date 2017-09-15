// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresServiceGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:postgres/postgres.dart';
import 'fruit.dart';
import 'fruit.orm.g.dart';

class FruitService extends Service {
  final PostgreSQLConnection connection;

  final bool allowRemoveAll;

  final bool allowQuery;

  FruitService(this.connection,
      {this.allowRemoveAll: false, this.allowQuery: false});

  FruitQuery buildQuery(Map params) {
    var query = new FruitQuery();
    if (params['query'] is Map) {
      query.where.id.equals(params['query']['id']);
      query.where.treeId.equals(params['query']['tree_id']);
      query.where.commonName.equals(params['query']['common_name']);
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

  Fruit applyData(data) {
    if (data is Fruit || data == null) {
      return data;
    }
    if (data is Map) {
      var query = new Fruit();
      if (data.containsKey('tree_id')) {
        query.treeId = data['tree_id'];
      }
      if (data.containsKey('common_name')) {
        query.commonName = data['common_name'];
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

  Future<List<Fruit>> index([Map params]) {
    return buildQuery(params).get(connection).toList();
  }

  Future<Fruit> create(data, [Map params]) {
    return FruitQuery.insertFruit(connection, applyData(data));
  }

  Future<Fruit> read(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.get(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<Fruit> remove(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.delete(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<Fruit> update(id, data, [Map params]) {
    return FruitQuery.updateFruit(connection, applyData(data));
  }

  Future<Fruit> modify(id, data, [Map params]) async {
    var query = await read(toId(id), params);
    if (data is Fruit) {
      query = data;
    }
    if (data is Map) {
      if (data.containsKey('tree_id')) {
        query.treeId = data['tree_id'];
      }
      if (data.containsKey('common_name')) {
        query.commonName = data['common_name'];
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
    return await FruitQuery.updateFruit(connection, query);
  }
}
