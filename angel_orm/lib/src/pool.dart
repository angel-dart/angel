import 'dart:async';
import 'package:pool/pool.dart';
import 'package:postgres/postgres.dart';

/// Connects to a PostgreSQL database, whether synchronously or asynchronously.
typedef FutureOr<PostgreSQLConnection> PostgreSQLConnector();

/// Pools connections to a PostgreSQL database.
class PostgreSQLConnectionPool {
  final List<PostgreSQLConnection> _connections = [];
  final List<int> _opened = [];
  int _index = 0;
  Pool _pool;

  /// The maximum number of concurrent connections to the database.
  ///
  /// Default: `5`
  final int concurrency;

  /// An optional timeout for pooled connections to execute.
  final Duration timeout;

  /// A function that connects this pool to the database, on-demand.
  final PostgreSQLConnector connector;

  PostgreSQLConnectionPool(this.connector,
      {this.concurrency: 5, this.timeout}) {
    _pool = new Pool(concurrency, timeout: timeout);
  }

  Future<PostgreSQLConnection> _connect() async {
    if (_connections.isEmpty) {
      for (int i = 0; i < concurrency; i++) {
        _connections.add(await connector());
      }
    }

    var connection = _connections[_index++];
    if (_index >= _connections.length) _index = 0;

    if (!_opened.contains(connection.hashCode)) await connection.open();

    return connection;
  }

  Future close() => Future.wait(_connections.map((c) => c.close()));

  /// Connects to the database, and then executes the [callback].
  ///
  /// Returns the result of [callback].
  Future<T> run<T>(FutureOr<T> callback(PostgreSQLConnection connection)) {
    return _pool.request().then((resx) {
      return _connect().then((connection) {
        return new Future<T>.sync(() => callback(connection))
            .whenComplete(() async {
          if (connection.isClosed) {
            _connections
              ..remove(connection)
              ..add(await connector());
          }
          resx.release();
        });
      });
    });
  }
}
