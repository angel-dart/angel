// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'foot.orm.g.dart';

class _PostgreSqlFootOrmImpl implements FootOrm {
  _PostgreSqlFootOrmImpl(this.connection);

  final PostgreSQLConnection connection;

  static Foot parseRow(List row) {
    return new Foot(
        id: (row[0] as String),
        legId: (row[1] as int),
        nToes: (row[2] as int),
        createdAt: (row[3] as DateTime),
        updatedAt: (row[4] as DateTime));
  }

  @override
  Future<Foot> getById(String id) async {
    var r = await connection.query(
        'SELECT  id, leg_id, n_toes, created_at, updated_at FROM "foots" WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<List<Foot>> getAll() async {
    var r = await connection.query(
        'SELECT  id, leg_id, n_toes, created_at, updated_at FROM "foots";');
    return r.map(parseRow).toList();
  }

  @override
  Future<Foot> createFoot(Foot model) async {
    model = model.copyWith(
        createdAt: new DateTime.now(), updatedAt: new DateTime.now());
    var r = await connection.query(
        'INSERT INTO "foots" ( "id", "leg_id", "n_toes", "created_at", "updated_at") VALUES (@id,@legId,@nToes,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "leg_id", "n_toes", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'legId': model.legId,
          'nToes': model.nToes,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  @override
  Future<Foot> updateFoot(Foot model) async {
    model = model.copyWith(updatedAt: new DateTime.now());
    var r = await connection.query(
        'UPDATE "foots" SET ( "id", "leg_id", "n_toes", "created_at", "updated_at") = (@id,@legId,@nToes,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "leg_id", "n_toes", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'legId': model.legId,
          'nToes': model.nToes,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }
}
