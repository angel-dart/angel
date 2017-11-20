// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: MigrationGenerator
// **************************************************************************

import 'package:angel_migration/angel_migration.dart';
import 'package:angel_orm/angel_orm.dart';

class TreeMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('trees', (table) {
      table.serial('id')..primaryKey();
      table.declare('rings', new ColumnType('smallint'))..unique();
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('trees');
  }
}
