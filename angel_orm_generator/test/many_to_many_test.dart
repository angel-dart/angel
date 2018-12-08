library angel_orm_generator.test;

import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';
import 'models/user.dart';
import 'common.dart';

main() {
  QueryExecutor executor;

  setUp(() async {
    executor = await connectToPostgres(['user', 'role', 'user_role']);
  });
}