// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'author.orm.g.dart';

class _PostgreSqlAuthorOrmImpl implements AuthorOrm {
  _PostgreSqlAuthorOrmImpl(this.connection);

  final PostgreSQLConnection connection;

  static Author parseRow(List row) {
    return new Author(
        id: (row[0] as String),
        name: (row[1] as String),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
  }

  @override
  Future<Author> getById(id) async {
    var r = await connection.query(
        'SELECTidnamecreated_atupdated_at FROM "authors" id = @id;',
        substitutionValues: {'id': id});
    parseRow(r.first);
  }
}
