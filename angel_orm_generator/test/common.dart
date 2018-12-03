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
    await conn
        .execute(await new File('test/models/$s.up.g.sql').readAsString());

  return new PostgresExecutor(conn);
}

class PostgresExecutor extends QueryExecutor {
  final PostgreSQLConnection connection;

  PostgresExecutor(this.connection);

  Future close() => connection.close();

  @override
  Future<List<List>> query(String query, List<String> returningFields) {
    var fields = returningFields.join(', ');
    var returning = 'RETURNING ($fields)';
    return connection.query('$query $returning');
  }
}
