// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'car.orm.g.dart';

class PostgreSqlCarOrm implements CarOrm {
  PostgreSqlCarOrm(this.connection);

  final PostgreSQLConnection connection;

  static Car parseRow(List row) {
    return new Car(
        id: (row[0] as String),
        make: (row[1] as String),
        description: (row[2] as String),
        familyFriendly: (row[3] as bool),
        recalledAt: (row[4] as DateTime),
        createdAt: (row[5] as DateTime),
        updatedAt: (row[6] as DateTime));
  }

  @override
  Future<Car> getById(String id) async {
    var r = await connection.query(
        'SELECT  id, make, description, family_friendly, recalled_at, created_at, updated_at FROM "cars" WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<Car> deleteById(String id) async {
    var r = await connection.query(
        'DELETE FROM "cars" WHERE id = @id RETURNING  "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at";',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<List<Car>> getAll() async {
    var r = await connection.query(
        'SELECT  id, make, description, family_friendly, recalled_at, created_at, updated_at FROM "cars";');
    return r.map(parseRow).toList();
  }

  @override
  Future<Car> createCar(Car model) async {
    model = model.copyWith(
        createdAt: new DateTime.now(), updatedAt: new DateTime.now());
    var r = await connection.query(
        'INSERT INTO "cars" ( "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at") VALUES (@id,@make,@description,@familyFriendly,CAST (@recalledAt AS timestamp),CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'make': model.make,
          'description': model.description,
          'familyFriendly': model.familyFriendly,
          'recalledAt': model.recalledAt,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  @override
  Future<Car> updateCar(Car model) async {
    model = model.copyWith(updatedAt: new DateTime.now());
    var r = await connection.query(
        'UPDATE "cars" SET ( "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at") = (@id,@make,@description,@familyFriendly,CAST (@recalledAt AS timestamp),CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'make': model.make,
          'description': model.description,
          'familyFriendly': model.familyFriendly,
          'recalledAt': model.recalledAt,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  CarQuery query() {
    return null;
  }
}
