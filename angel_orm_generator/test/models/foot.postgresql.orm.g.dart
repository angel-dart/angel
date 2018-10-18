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
}
