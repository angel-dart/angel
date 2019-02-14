import 'dart:async';
import 'package:args/command_runner.dart';
import 'runner.dart';

/// Runs the Angel Migration CLI.
Future runMigrations(MigrationRunner migrationRunner, List<String> args) {
  var cmd = new CommandRunner('migration_runner', 'Executes Angel migrations.')
    ..addCommand(new _UpCommand(migrationRunner))
    ..addCommand(new _RefreshCommand(migrationRunner))
    ..addCommand(new _ResetCommand(migrationRunner))
    ..addCommand(new _RollbackCommand(migrationRunner));
  return cmd.run(args).then((_) => migrationRunner.close());
}

class _UpCommand extends Command {
  _UpCommand(this.migrationRunner);

  String get name => 'up';
  String get description => 'Runs outstanding migrations.';

  final MigrationRunner migrationRunner;

  @override
  run() {
    return migrationRunner.up();
  }
}

class _ResetCommand extends Command {
  _ResetCommand(this.migrationRunner);

  String get name => 'reset';
  String get description => 'Resets the database.';

  final MigrationRunner migrationRunner;

  @override
  run() {
    return migrationRunner.reset();
  }
}

class _RefreshCommand extends Command {
  _RefreshCommand(this.migrationRunner);

  String get name => 'refresh';
  String get description =>
      'Resets the database, and then re-runs all migrations.';

  final MigrationRunner migrationRunner;

  @override
  run() {
    return migrationRunner.reset().then((_) => migrationRunner.up());
  }
}

class _RollbackCommand extends Command {
  _RollbackCommand(this.migrationRunner);

  String get name => 'rollback';
  String get description => 'Undoes the last batch of migrations.';

  final MigrationRunner migrationRunner;

  @override
  run() {
    return migrationRunner.rollback();
  }
}
