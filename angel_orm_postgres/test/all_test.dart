import 'dart:async';

import 'package:angel_orm_postgres/angel_orm_postgres.dart';
import 'package:angel_orm_test/angel_orm_test.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  PostgreSQLConnection _connect() {
    return PostgreSQLConnection('localhost', 5432, 'angel_orm_test');
  }

  group('single', () {
    PostgreSqlExecutor executor;
    PostgreSQLConnection c = _connect();

    setUp(() async {
      var c = _connect();
      await c.open();
      executor = PostgreSqlExecutor(c);
    });

    tearDown(() => executor.close());

    ormTests(() => executor);
  });
}
