import 'table.dart';

abstract class Schema {
  void drop(String tableName, {bool cascade: false});

  void dropAll(Iterable<String> tableNames, {bool cascade: false}) {
    tableNames.forEach((n) => drop(n, cascade: cascade));
  }

  void create(String tableName, void callback(Table table));

  void createIfNotExists(String tableName, void callback(Table table));

  void alter(String tableName, void callback(MutableTable table));
}
