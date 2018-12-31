import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:pool/pool.dart';
import 'package:postgres/postgres.dart';

/// A [QueryExecutor] that queries a PostgreSQL database.
class PostgreSQLExecutor extends QueryExecutor {
  PostgreSQLExecutionContext connection;

  PostgreSQLExecutor(this.connection);

  /// Closes the connection.
  Future close() => (connection as PostgreSQLConnection).close();

  @override
  Future<List<List>> query(
      String query, Map<String, dynamic> substitutionValues,
      [List<String> returningFields]) {
    if (returningFields != null) {
      var fields = returningFields.join(', ');
      var returning = 'RETURNING $fields';
      query = '$query $returning';
    }

    return connection.query(query, substitutionValues: substitutionValues);
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function() f) async {
    if (connection is! PostgreSQLConnection) return await f();
    var old = connection;
    T result;
    try {
      await (connection as PostgreSQLConnection).transaction((ctx) async {
        connection = ctx;
        result = await f();
      });
    } finally {
      connection = old;
      return result;
    }
  }
}

/// A [QueryExecutor] that manages a pool of PostgreSQL connections.
class PostgreSQLExecutorPool extends QueryExecutor {
  final int size;
  final PostgreSQLConnection Function() connectionFactory;
  final List<PostgreSQLExecutor> _connections = [];
  int _index = 0;
  final Pool _pool, _connMutex = new Pool(1);

  PostgreSQLExecutorPool(this.size, this.connectionFactory)
      : _pool = new Pool(size) {
    assert(size > 0, 'Connection pool cannot be empty.');
  }

  /// Closes all connections.
  Future close() async {
    _pool.close();
    _connMutex.close();
    return Future.wait(_connections.map((c) => c.close()));
  }

  Future _open() async {
    if (_connections.isEmpty) {
      _connections.addAll(await Future.wait(new List.generate(size, (_) {
        var conn = connectionFactory();
        return conn.open().then((_) => new PostgreSQLExecutor(conn));
      })));
    }
  }

  Future<PostgreSQLExecutor> _next() {
    return _connMutex.withResource(() async {
      await _open();
      if (_index >= size) _index = 0;
      return _connections[_index++];
    });
  }

  @override
  Future<List<List>> query(
      String query, Map<String, dynamic> substitutionValues,
      [List<String> returningFields]) {
    return _pool.withResource(() async {
      var executor = await _next();
      return executor.query(query, substitutionValues, returningFields);
    });
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function() f) {
    return _pool.withResource(() async {
      var executor = await _next();
      return executor.transaction(f);
    });
  }
}
