// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'fruit.orm.g.dart';

class _PostgreSqlFruitOrmImpl implements FruitOrm {
  _PostgreSqlFruitOrmImpl(this.connection);

  final PostgreSQLConnection connection;

  static Fruit parseRow(List row) {
    return new Fruit(
        id: (row[0] as String),
        treeId: (row[1] as int),
        commonName: (row[2] as String),
        createdAt: (row[3] as DateTime),
        updatedAt: (row[4] as DateTime));
  }
}
