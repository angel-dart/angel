import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'models/role.dart';
import 'models/role.orm.g.dart';
import 'models/user.dart';
import 'models/user.orm.g.dart';
import 'common.dart';

main() {
  PostgreSQLConnection connection;
  Role manager, clerk;
  User john;

  setUp(() async {
    connection = await connectToPostgres(['user', 'role']);


  });

  tearDown(() => connection.close());
}