import 'dart:async';
import 'package:furlong/furlong.dart';

class TodoMigration extends Migration {
  String get name => "Todos table";

  @override
  Future create(Migrator migrator) async {
    migrator.create("todos", (table) {
      table.id();
      table.varChar("group_id").nullable = true;
      table.varChar("title").nullable = true;
      table.varChar("text");
    });
  }

  @override
  Future destroy(Migrator migrator) async {
    migrator.drop(["todos"]);
  }
}
