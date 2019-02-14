import 'dart:async';
import 'package:angel_migration/angel_migration.dart';

abstract class MigrationRunner {
  void addMigration(Migration migration);

  Future up();

  Future rollback();

  Future reset();

  Future close();
}
