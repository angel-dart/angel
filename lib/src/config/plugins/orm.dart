import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_orm_postgres/angel_orm_postgres.dart';
import 'package:postgres/postgres.dart';

Future<void> configureServer(Angel app) async {
  var connection = await connectToPostgres(app.configuration);
  await connection.open();

  app
    ..container.registerSingleton<QueryExecutor>(PostgreSQLExecutor(connection))
    ..shutdownHooks.add((_) => connection.close());
}

Future<PostgreSQLConnection> connectToPostgres(Map configuration) async {
  var postgresConfig = configuration['postgres'] as Map ?? {};
  var connection = PostgreSQLConnection(
      postgresConfig['host'] as String ?? 'localhost',
      postgresConfig['port'] as int ?? 5432,
      postgresConfig['database_name'] as String ??
          Platform.environment['USER'] ??
          Platform.environment['USERNAME'],
      username: postgresConfig['username'] as String,
      password: postgresConfig['password'] as String,
      timeZone: postgresConfig['time_zone'] as String ?? 'UTC',
      timeoutInSeconds: postgresConfig['timeout_in_seconds'] as int ?? 30,
      useSSL: postgresConfig['use_ssl'] as bool ?? false);
  return connection;
}
