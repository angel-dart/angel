import 'package:angel_migration/angel_migration.dart';
import 'package:angel_migration_runner/angel_migration_runner.dart';
import 'package:angel_migration_runner/postgres.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import '../../angel_migration/example/todo.dart';

var migrationRunner = new PostgresMigrationRunner(
  new PostgreSQLConnection('127.0.0.1', 5432, 'test',
      username: 'postgres', password: 'postgres'),
  migrations: [
    new UserMigration(),
    new TodoMigration(),
    new FooMigration(),
  ],
);

main(List<String> args) => runMigrations(migrationRunner, args);

class FooMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('foos', (table) {
      table
        ..serial('id').primaryKey()
        ..varChar('bar', length: 64)
        ..timeStamp('created_at').defaultsTo(currentTimestamp);
    });
  }

  @override
  void down(Schema schema) => schema.drop('foos');
}
