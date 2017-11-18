// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: MigrationGenerator
// **************************************************************************

import 'package:angel_migration/angel_migration.dart';

class CarMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('cars', (table) {
      table.serial('id')..primaryKey();
      table.varchar('make');
      table.varchar('description');
      table.boolean('family_friendly');
      table.timeStamp('recalled_at');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('cars');
  }
}
