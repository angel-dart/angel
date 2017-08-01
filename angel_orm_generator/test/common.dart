import 'dart:async';
import 'dart:io';
import 'package:postgres/postgres.dart';

Future<PostgreSQLConnection> connectToPostgres(Iterable<String> schemas) async {
  var conn = new PostgreSQLConnection('127.0.0.1', 5432, 'angel_orm_test',
      username: Platform.environment['POSTGRES_USERNAME'] ?? 'postgres',
      password: Platform.environment['POSTGRES_PASSWORD'] ?? 'password');
  await conn.open();

  for (var s in schemas)
    await conn
        .execute(await new File('test/models/$s.up.g.sql').readAsString());

  return conn;
}
