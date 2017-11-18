// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: MigrationGenerator
// **************************************************************************

import 'package:angel_migration/angel_migration.dart';

class FruitMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('fruits', (table) {
      table.serial('id')..primaryKey();
      table.integer('tree_id');
      table.varchar('common_name');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('fruits');
  }
}
