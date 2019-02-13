import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:logging/logging.dart';
import 'package:pool/pool.dart';
import 'package:postgres/postgres.dart';

/// A [QueryExecutor] that queries a PostgreSQL database.
class PostgreSQLExecutor extends QueryExecutor {
  PostgreSQLExecutionContext _connection;

  /// An optional [Logger] to print information to.
  final Logger logger;

  PostgreSQLExecutor(this._connection, {this.logger});

  /// The underlying connection.
  PostgreSQLExecutionContext get connection => _connection;

  /// Closes the connection.
  Future close() => (_connection as PostgreSQLConnection).close();

  @override
  Future<List<List>> query(
      String tableName, String query, Map<String, dynamic> substitutionValues,
      [List<String> returningFields]) {
    if (returningFields != null) {
      var fields = returningFields.join(', ');
      var returning = 'RETURNING $fields';
      query = '$query $returning';
    }

    logger?.fine('Query: $query');
    logger?.fine('Values: $substitutionValues');
    return _connection.query(query, substitutionValues: substitutionValues);
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function() f) async {
    if (_connection is! PostgreSQLConnection) return await f();
    var old = _connection;
    T result;
    try {
      logger?.fine('Entering transaction');
      await (_connection as PostgreSQLConnection).transaction((ctx) async {
        _connection = ctx;
        result = await f();
      });
    } finally {
      _connection = old;
      logger?.fine('Exiting transaction');
      return result;
    }
  }
}

/// A [QueryExecutor] that manages a pool of PostgreSQL connections.
class PostgreSQLExecutorPool extends QueryExecutor {
  /// The maximum amount of concurrent connections.
  final int size;

  /// Creates a new [PostgreSQLConnection], on demand.
  ///
  /// The created connection should **not** be open.
  final PostgreSQLConnection Function() connectionFactory;

  /// An optional [Logger] to print information to.
  final Logger logger;

  final List<PostgreSQLExecutor> _connections = [];
  int _index = 0;
  final Pool _pool, _connMutex = new Pool(1);

  PostgreSQLExecutorPool(this.size, this.connectionFactory, {this.logger})
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
        logger?.fine('Spawning connections...');
        var conn = connectionFactory();
        return conn
            .open()
            .then((_) => new PostgreSQLExecutor(conn, logger: logger));
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
      String tableName, String query, Map<String, dynamic> substitutionValues,
      [List<String> returningFields]) {
    return _pool.withResource(() async {
      var executor = await _next();
      return executor.query(
          tableName, query, substitutionValues, returningFields);
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
