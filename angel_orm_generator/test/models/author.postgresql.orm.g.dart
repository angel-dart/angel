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
  Future<Author> getById(String id) async {
    var r = await connection.query(
        'SELECT  id, name, created_at, updated_at FROM "authors" WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<List<Author>> getAll() async {
    var r = await connection
        .query('SELECT  id, name, created_at, updated_at FROM "authors";');
    return r.map(parseRow).toList();
  }

  @override
  Future<Author> createAuthor(Author model) async {
    model = model.copyWith(
        createdAt: new DateTime.now(), updatedAt: new DateTime.now());
    var r = await connection.query(
        'INSERT INTO "authors" ( "id", "name", "created_at", "updated_at") VALUES (@id,@name,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "name", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'name': model.name,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  @override
  Future<Author> updateAuthor(Author model) async {
    model = model.copyWith(updatedAt: new DateTime.now());
    var r = await connection.query(
        'UPDATE "authors" SET ( "id", "name", "created_at", "updated_at") = (@id,@name,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "name", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'name': model.name,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }
}
