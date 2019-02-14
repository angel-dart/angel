import 'package:angel_migration_runner/angel_migration_runner.dart';
import 'package:angel_migration_runner/postgres.dart';
import 'package:postgres/postgres.dart';
import '../../angel_migration/example/todo.dart';

var migrationRunner = new PostgresMigrationRunner(
  new PostgreSQLConnection('127.0.0.1', 5432, 'test',
      username: 'postgres', password: 'postgres'),
  migrations: [
    new UserMigration(),
    new TodoMigration(),
  ],
);

main(List<String> args) => runMigrations(migrationRunner, args);
