import 'dart:async';
import 'dart:io';
import 'package:postgres/postgres.dart';

Future<PostgreSQLConnection> connectToPostgres() async {
  var conn = new PostgreSQLConnection('127.0.0.1', 5432, 'angel_orm_test',
      username: Platform.environment['POSTGRES_USERNAME'] ?? 'postgres',
      password: Platform.environment['POSTGRES_PASSWORD'] ?? 'password');
  await conn.open();

  var query = await new File('test/models/car.up.g.sql').readAsString();
  await conn.execute(query);
  query = await new File('test/models/author.up.g.sql').readAsString();
  await conn.execute(query);
  query = await new File('test/models/book.up.g.sql').readAsString();
  await conn.execute(query);

  return conn;
}
