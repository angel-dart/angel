import 'dart:io';
import 'package:angel_orm_postgres/angel_orm_postgres.dart';
import 'package:postgres/postgres.dart';

main() async {
  var executor = new PostgreSQLExecutorPool(Platform.numberOfProcessors, () {
    return new PostgreSQLConnection('localhost', 5432, 'angel_orm_test');
  });

  var rows = await executor.query('SELECT * FROM users', {});
  print(rows);
}
