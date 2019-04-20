import 'package:angel_migration_runner/angel_migration_runner.dart';
import 'package:angel_migration_runner/postgres.dart';
import 'connect.dart';
import 'todo.dart';

main(List<String> args) {
  var runner = PostgresMigrationRunner(conn, migrations: [
    TodoMigration(),
  ]);
  return runMigrations(runner, args);
}
