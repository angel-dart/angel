// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'customer.orm.g.dart';

class _PostgreSqlCustomerOrmImpl implements CustomerOrm {
  _PostgreSqlCustomerOrmImpl(this.connection);

  final PostgreSQLConnection connection;

  static Customer parseRow(List row) {
    return new Customer(
        id: (row[0] as String),
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime));
  }

  @override
  Future<Customer> getById() async {
    var r = await connection.query(
        'SELECTidcreated_atupdated_at FROM "customers" id = @id;',
        substitutionValues: {'id': id});
    parseRow(r.first);
  }
}
