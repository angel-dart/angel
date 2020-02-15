import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:logging/logging.dart';
// import 'package:pool/pool.dart';
import 'package:sqljocky5/connection/connection.dart';
import 'package:sqljocky5/sqljocky.dart';

class MySqlExecutor extends QueryExecutor {
  /// An optional [Logger] to write to.
  final Logger logger;

  final Querier _connection;

  MySqlExecutor(this._connection, {this.logger});

  Future<void> close() {
    if (_connection is MySqlConnection) {
      return (_connection as MySqlConnection).close();
    } else {
      return Future.value();
    }
  }

  Future<Transaction> _startTransaction() {
    if (_connection is Transaction) {
      return Future.value(_connection as Transaction);
    } else if (_connection is MySqlConnection) {
      return (_connection as MySqlConnection).begin();
    } else {
      throw StateError('Connection must be transaction or connection');
    }
  }

  @override
  Future<List<List>> query(
      String tableName, String query, Map<String, dynamic> substitutionValues,
      [List<String> returningFields]) {
    // Change @id -> ?
    for (var name in substitutionValues.keys) {
      query = query.replaceAll('@$name', '?');
    }

    logger?.fine('Query: $query');
    logger?.fine('Values: $substitutionValues');

    if (returningFields?.isNotEmpty != true) {
      return _connection
          .prepared(query, substitutionValues.values)
          .then((results) => results.map((r) => r.toList()).toList());
    } else {
      return Future(() async {
        var tx = await _startTransaction();

        try {
          var writeResults =
              await tx.prepared(query, substitutionValues.values);
          var fieldSet = returningFields.map((s) => '`$s`').join(',');
          var fetchSql = 'select $fieldSet from $tableName where id = ?;';
          logger?.fine(fetchSql);
          var readResults =
              await tx.prepared(fetchSql, [writeResults.insertId]);
          var mapped = readResults.map((r) => r.toList()).toList();
          await tx.commit();
          return mapped;
        } catch (_) {
          await tx?.rollback();
          rethrow;
        }
      });
    }
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function(QueryExecutor) f) async {
    if (_connection is Transaction) {
      return await f(this);
    }

    Transaction tx;
    try {
      tx = await _startTransaction();
      var executor = MySqlExecutor(tx, logger: logger);
      var result = await f(executor);
      await tx.commit();
      return result;
    } catch (_) {
      await tx?.rollback();
      rethrow;
    }
  }
}
