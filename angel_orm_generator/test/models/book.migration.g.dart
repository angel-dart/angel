// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: MigrationGenerator
// **************************************************************************

import 'package:angel_migration/angel_migration.dart';

class BookMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('books', (table) {
      table.serial('id')..primaryKey();
      table.varchar('name');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.integer('author_id').references('authors', 'id').onDeleteCascade();
    });
  }

  @override
  down(Schema schema) {
    schema.drop('books');
  }
}
