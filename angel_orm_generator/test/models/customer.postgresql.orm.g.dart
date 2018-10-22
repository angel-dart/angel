// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PostgreSqlOrmGenerator
// **************************************************************************

part of 'customer.orm.g.dart';

class PostgreSqlCustomerOrm implements CustomerOrm {
  PostgreSqlCustomerOrm(this.connection);

  final PostgreSQLConnection connection;

  static Customer parseRow(List row) {
    return new Customer(
        id: (row[0] as String),
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime));
  }

  @override
  Future<Customer> getById(String id) async {
    var r = await connection.query(
        'SELECT  id, created_at, updated_at FROM "customers" WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<Customer> deleteById(String id) async {
    var r = await connection.query(
        'DELETE FROM "customers" WHERE id = @id RETURNING  "id", "created_at", "updated_at";',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<List<Customer>> getAll() async {
    var r = await connection
        .query('SELECT  id, created_at, updated_at FROM "customers";');
    return r.map(parseRow).toList();
  }

  @override
  Future<Customer> createCustomer(Customer model) async {
    model = model.copyWith(
        createdAt: new DateTime.now(), updatedAt: new DateTime.now());
    var r = await connection.query(
        'INSERT INTO "customers" ( "id", "created_at", "updated_at") VALUES (@id,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  @override
  Future<Customer> updateCustomer(Customer model) async {
    model = model.copyWith(updatedAt: new DateTime.now());
    var r = await connection.query(
        'UPDATE "customers" SET ( "id", "created_at", "updated_at") = (@id,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  CustomerQuery query() {
    return null;
  }
}
