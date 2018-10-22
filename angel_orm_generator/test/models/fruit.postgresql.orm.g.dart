// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'fruit.orm.g.dart';

class PostgreSqlFruitOrm implements FruitOrm {
  PostgreSqlFruitOrm(this.connection);

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
  Future<Fruit> getById(String id) async {
    var r = await connection.query(
        'SELECT  id, tree_id, common_name, created_at, updated_at FROM "fruits" WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<Fruit> deleteById(String id) async {
    var r = await connection.query(
        'DELETE FROM "fruits" WHERE id = @id RETURNING  "id", "tree_id", "common_name", "created_at", "updated_at";',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<List<Fruit>> getAll() async {
    var r = await connection.query(
        'SELECT  id, tree_id, common_name, created_at, updated_at FROM "fruits";');
    return r.map(parseRow).toList();
  }

  @override
  Future<Fruit> createFruit(Fruit model) async {
    model = model.copyWith(
        createdAt: new DateTime.now(), updatedAt: new DateTime.now());
    var r = await connection.query(
        'INSERT INTO "fruits" ( "id", "tree_id", "common_name", "created_at", "updated_at") VALUES (@id,@treeId,@commonName,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "tree_id", "common_name", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'treeId': model.treeId,
          'commonName': model.commonName,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  @override
  Future<Fruit> updateFruit(Fruit model) async {
    model = model.copyWith(updatedAt: new DateTime.now());
    var r = await connection.query(
        'UPDATE "fruits" SET ( "id", "tree_id", "common_name", "created_at", "updated_at") = (@id,@treeId,@commonName,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "tree_id", "common_name", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'treeId': model.treeId,
          'commonName': model.commonName,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  FruitQuery query() {
    return null;
  }
}
