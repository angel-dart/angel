import 'dart:async';
import 'dart:io';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_orm_postgres/angel_orm_postgres.dart';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';

FutureOr<QueryExecutor> Function() pg(Iterable<String> schemas) {
  return () => connectToPostgres(schemas);
}

Future<void> closePg(QueryExecutor executor) =>
    (executor as PostgreSqlExecutor).close();

Future<PostgreSqlExecutor> connectToPostgres(Iterable<String> schemas) async {
  var conn = new PostgreSQLConnection('127.0.0.1', 5432, 'angel_orm_test',
      username: Platform.environment['POSTGRES_USERNAME'] ?? 'postgres',
      password: Platform.environment['POSTGRES_PASSWORD'] ?? 'password');
  await conn.open();

  for (var s in schemas)
    await conn.execute(await new File('test/migrations/$s.sql').readAsString());

  return new PostgreSqlExecutor(conn, logger: Logger.root);
}
