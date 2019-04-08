import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_orm/src/query.dart';
import 'package:logging/logging.dart';
import 'package:pool/pool.dart';
import 'package:sqljocky5/connection/connection.dart';
import 'package:sqljocky5/sqljocky.dart';

class MySqlExecutor extends QueryExecutor {
  /// An optional [Logger] to write to.
  final Logger logger;

  final MySqlConnection _connection;
  Transaction _transaction;

  MySqlExecutor(this._connection, {this.logger});

  Future<void> close() => _connection.close();

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
        _transaction ??= await _connection.begin();

        try {
          var writeResults =
              await _transaction.prepared(query, substitutionValues.values);
          var fieldSet = returningFields.map((s) => '`$s`').join(',');
          var fetchSql = 'select $fieldSet from $tableName where id = ?;';
          logger?.fine(fetchSql);
          var readResults =
              await _transaction.prepared(fetchSql, [writeResults.insertId]);
          var mapped = readResults.map((r) => r.toList()).toList();
          await _transaction.commit();
          return mapped;
        } catch (_) {
          await _transaction?.rollback();
          rethrow;
        }
      });
    }
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function() f) {
    if (_transaction != null) {
      return Future.sync(f);
    } else {
      return Future(() async {
        try {
          _transaction = await _connection.begin();
          var result = await f();
          await _transaction.commit();
          return result;
        } catch (_) {
          await _transaction?.rollback();
          rethrow;
        }
      });
    }
  }
}
