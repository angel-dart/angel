import 'dart:async';
import 'package:furlong/furlong.dart';

class GroupMigration extends Migration {
  String get name => "Groups table";

  @override
  Future create(Migrator migrator) async {
    migrator.create("groups", (table) {
      table.id();
      table.varChar("name");
    });
  }

  @override
  Future destroy(Migrator migrator) async {
    migrator.drop(["groups"]);
  }
}
