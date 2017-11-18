// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: MigrationGenerator
// **************************************************************************

import 'package:angel_migration/angel_migration.dart';

class AuthorMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('authors', (table) {
      table.serial('id')..primaryKey();
      table.varchar('name', length: 255)
        ..defaultsTo('Tobe Osakwe')
        ..unique();
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('authors');
  }
}
