// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'role.orm.g.dart';

class _PostgreSqlRoleOrmImpl implements RoleOrm {
  _PostgreSqlRoleOrmImpl(this.connection);

  final PostgreSQLConnection connection;

  static Role parseRow(List row) {
    return new Role(
        id: (row[0] as String),
        name: (row[1] as String),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
  }

  @override
  Future<Role> getById() async {
    var r = await connection.query(
        'SELECTidnamecreated_atupdated_at FROM "roles" id = @id;',
        substitutionValues: {'id': id});
    parseRow(r.first);
  }
}
