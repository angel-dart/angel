// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: MigrationGenerator
// **************************************************************************

import 'package:angel_migration/angel_migration.dart';

class RoleMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('roles', (table) {
      table.serial('id')..primaryKey();
      table.varchar('name');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('roles');
  }
}
