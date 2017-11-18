// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: MigrationGenerator
// **************************************************************************

import 'package:angel_migration/angel_migration.dart';

class UserMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('users', (table) {
      table.serial('id')..primaryKey();
      table.varchar('username');
      table.varchar('password');
      table.varchar('email');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.integer('role_id').references('roles', 'id');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('users');
  }
}
