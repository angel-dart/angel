library angel.migrations;

import 'dart:async';
import 'dart:io';
import 'package:angel_configuration/angel_configuration.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:furlong/furlong.dart';
import 'package:sqljocky/sqljocky.dart';
export 'group.dart';
export 'todo.dart';

Future<ConnectionPool> createPool() async {
  var app = new Angel();
  await app.configure(loadConfigurationFile());
  Map config = app.properties["furlong"];

  if (config == null)
    throw new Exception(
        "Please provide Furlong configuration with your configuration file.");

  String type = config["type"] ?? "mysql";

  if (type == "mysql") {
    return new ConnectionPool(
        host: config["host"] ?? "localhost",
        port: config["port"] ?? 3306,
        user: config["username"],
        password: config["password"],
        db: config["database"],
        useSSL: config["ssl"] == true);
  } else
    throw new Exception("Unsupported database driver '$type'.");
}

migrateDown(List<Migration> migrations) async {
  print("Undoing all migrations...");
  var pool = await createPool();
  var furlong = new Furlong(pool, migrations: migrations);
  await furlong.down();
  print("Done.");
  exit(0);
}

migrateReset(List<Migration> migrations) async {
  var pool = await createPool();
  var furlong = new Furlong(pool, migrations: migrations);
  await furlong.reset();
  print("Done.");
  exit(0);
}

migrateRevert(List<Migration> migrations) async {
  print("Reverting last batch...");
  var pool = await createPool();
  var furlong = new Furlong(pool, migrations: migrations);
  await furlong.revert();
  print("Done.");
  exit(0);
}

migrateUp(List<Migration> migrations) async {
  print("Running all outstanding migrations...");
  var pool = await createPool();
  var furlong = new Furlong(pool, migrations: migrations);
  await furlong.up();
  print("Done.");
  exit(0);
}