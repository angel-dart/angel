import 'dart:async';
import 'package:furlong/furlong.dart';

class UsersMigration extends Migration {
  @override
  String get name => "Users table";

  @override
  Future create(Migrator migrator) async {
    migrator.create("users", (table) {
      table.id();
      table.string("username");
      table.string("email");
      table.string("password");
      table.dateTime("created_at");
      table.dateTime("updated_at").nullable = true;
    });
  }

  @override
  Future destroy(Migrator migrator) async {
    migrator.drop(["users"]);
  }
}