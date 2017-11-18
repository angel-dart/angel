// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: MigrationGenerator
// **************************************************************************

import 'package:angel_migration/angel_migration.dart';

class FootMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('foots', (table) {
      table.serial('id')..primaryKey();
      table.integer('leg_id');
      table.integer('n_toes');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('foots');
  }
}
