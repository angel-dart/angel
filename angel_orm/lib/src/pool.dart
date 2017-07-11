import 'dart:async';
import 'package:pool/pool.dart';
import 'package:postgres/postgres.dart';

/// Connects to a PostgreSQL database, whether synchronously or asynchronously.
typedef FutureOr<PostgreSQLConnection> PostgreSQLConnector();

/// Pools connections to a PostgreSQL database.
class PostgreSQLConnectionPool {
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
    var connection = await connector() as PostgreSQLConnection;
    await connection.open();
    return connection;
  }

  /// Connects to the database, and then executes the [callback].
  ///
  /// Returns the result of [callback].
  Future<T> run<T>(FutureOr<T> callback(PostgreSQLConnection connection)) {
    return _pool.request().then((resx) {
      return _connect().then((connection) {
        return new Future<T>.sync(() => callback(connection))
            .whenComplete(() async {
          if (!connection.isClosed) await connection.close();
          resx.release();
        });
      });
    });
  }
}
