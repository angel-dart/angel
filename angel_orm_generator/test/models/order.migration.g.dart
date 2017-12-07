// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: MigrationGenerator
// **************************************************************************

import 'package:angel_migration/angel_migration.dart';

class OrderMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('orders', (table) {
      table.serial('id')..primaryKey();
      table.integer('customer_id');
      table.integer('employee_id');
      table.timeStamp('order_date');
      table.integer('shipper_id');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('orders');
  }
}
