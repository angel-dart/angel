// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'role.orm.g.dart';

class PostgreSqlRoleOrm implements RoleOrm {
  PostgreSqlRoleOrm(this.connection);

  final PostgreSQLConnection connection;

  static Role parseRow(List row) {
    return new Role(
        id: (row[0] as String),
        name: (row[1] as String),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
  }

  @override
  Future<Role> getById(String id) async {
    var r = await connection.query(
        'SELECT  id, name, created_at, updated_at FROM "roles" WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<Role> deleteById(String id) async {
    var r = await connection.query(
        'DELETE FROM "roles" WHERE id = @id RETURNING  "id", "name", "created_at", "updated_at";',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<List<Role>> getAll() async {
    var r = await connection
        .query('SELECT  id, name, created_at, updated_at FROM "roles";');
    return r.map(parseRow).toList();
  }

  @override
  Future<Role> createRole(Role model) async {
    model = model.copyWith(
        createdAt: new DateTime.now(), updatedAt: new DateTime.now());
    var r = await connection.query(
        'INSERT INTO "roles" ( "id", "name", "created_at", "updated_at") VALUES (@id,@name,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "name", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'name': model.name,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  @override
  Future<Role> updateRole(Role model) async {
    model = model.copyWith(updatedAt: new DateTime.now());
    var r = await connection.query(
        'UPDATE "roles" SET ( "id", "name", "created_at", "updated_at") = (@id,@name,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "name", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'name': model.name,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  RoleQuery query() {
    return null;
  }
}
