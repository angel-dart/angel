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

  @override
  Future<Fruit> getById() async {
    var r = await connection.query(
        'SELECTidtree_idcommon_namecreated_atupdated_at FROM "fruits" id = @id;',
        substitutionValues: {'id': id});
    parseRow(r.first);
  }
}
