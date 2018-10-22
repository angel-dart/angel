// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'car.orm.g.dart';

class _PostgreSqlCarOrmImpl implements CarOrm {
  _PostgreSqlCarOrmImpl(this.connection);

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
  Future<Car> getById() async {
    var r = await connection.query(
        'SELECTidmakedescriptionfamily_friendlyrecalled_atcreated_atupdated_at FROM "cars" id = @id;',
        substitutionValues: {'id': id});
    parseRow(r.first);
  }
}
