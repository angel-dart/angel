import 'dart:async';
import 'dart:io';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_orm_mysql/angel_orm_mysql.dart';
import 'package:logging/logging.dart';
import 'package:sqljocky5/sqljocky.dart';

FutureOr<QueryExecutor> Function() my(Iterable<String> schemas) {
  return () => connectToMySql(schemas);
}

Future<void> closeMy(QueryExecutor executor) =>
    (executor as MySqlExecutor).close();

Future<MySqlExecutor> connectToMySql(Iterable<String> schemas) async {
  var settings = ConnectionSettings(
      db: 'angel_orm_test',
      user: Platform.environment['MYSQL_USERNAME'] ?? 'angel_orm_test',
      password: Platform.environment['MYSQL_PASSWORD'] ?? 'angel_orm_test');
  var connection = await MySqlConnection.connect(settings);
  var logger = Logger('angel_orm_mysql');

  for (var s in schemas)
    await connection
        .execute(await new File('test/migrations/$s.sql').readAsString());

  return MySqlExecutor(connection, logger: logger);
}
