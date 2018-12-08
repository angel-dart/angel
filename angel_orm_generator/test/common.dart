import 'dart:async';
import 'dart:io';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';

Future<PostgresExecutor> connectToPostgres(Iterable<String> schemas) async {
  var conn = new PostgreSQLConnection('127.0.0.1', 5432, 'angel_orm_test',
      username: Platform.environment['POSTGRES_USERNAME'] ?? 'postgres',
      password: Platform.environment['POSTGRES_PASSWORD'] ?? 'password');
  await conn.open();

  for (var s in schemas)
    await conn.execute(await new File('test/migrations/$s.sql').readAsString());

  return new PostgresExecutor(conn);
}

class PostgresExecutor extends QueryExecutor {
  PostgreSQLExecutionContext connection;

  PostgresExecutor(this.connection);

  Future close() => (connection as PostgreSQLConnection).close();

  @override
  Future<List<List>> query(String query, [List<String> returningFields]) {
    if (returningFields != null) {
      var fields = returningFields.join(', ');
      var returning = 'RETURNING $fields';
      query = '$query $returning';
    }

    if (!Platform.environment.containsKey('STFU')) print('Running: $query');
    return connection.query(query);
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
