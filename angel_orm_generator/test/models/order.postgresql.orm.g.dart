// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'order.orm.g.dart';

class _PostgreSqlOrderOrmImpl implements OrderOrm {
  _PostgreSqlOrderOrmImpl(this.connection);

  final PostgreSQLConnection connection;

  static Order parseRow(List row) {
    return new Order(
        id: (row[0] as String),
        customerId: (row[1] as int),
        employeeId: (row[2] as int),
        orderDate: (row[3] as DateTime),
        shipperId: (row[4] as int),
        createdAt: (row[5] as DateTime),
        updatedAt: (row[6] as DateTime));
  }
}
