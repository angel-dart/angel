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

  @override
  Future<Order> getById(String id) async {
    var r = await connection.query(
        'SELECT  id, customer_id, employee_id, order_date, shipper_id, created_at, updated_at FROM "orders" WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': int.parse(id)});
    return parseRow(r.first);
  }

  @override
  Future<List<Order>> getAll() async {
    var r = await connection.query(
        'SELECT  id, customer_id, employee_id, order_date, shipper_id, created_at, updated_at FROM "orders";');
    return r.map(parseRow).toList();
  }

  @override
  Future<Order> createOrder(Order model) async {
    model = model.copyWith(
        createdAt: new DateTime.now(), updatedAt: new DateTime.now());
    var r = await connection.query(
        'INSERT INTO "orders" ( "id", "customer_id", "employee_id", "order_date", "shipper_id", "created_at", "updated_at") VALUES (@id,@customerId,@employeeId,CAST (@orderDate AS timestamp),@shipperId,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "customer_id", "employee_id", "order_date", "shipper_id", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'customerId': model.customerId,
          'employeeId': model.employeeId,
          'orderDate': model.orderDate,
          'shipperId': model.shipperId,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }

  @override
  Future<Order> updateOrder(Order model) async {
    model = model.copyWith(updatedAt: new DateTime.now());
    var r = await connection.query(
        'UPDATE "orders" SET ( "id", "customer_id", "employee_id", "order_date", "shipper_id", "created_at", "updated_at") = (@id,@customerId,@employeeId,CAST (@orderDate AS timestamp),@shipperId,CAST (@createdAt AS timestamp),CAST (@updatedAt AS timestamp)) RETURNING  "id", "customer_id", "employee_id", "order_date", "shipper_id", "created_at", "updated_at";',
        substitutionValues: {
          'id': model.id,
          'customerId': model.customerId,
          'employeeId': model.employeeId,
          'orderDate': model.orderDate,
          'shipperId': model.shipperId,
          'createdAt': model.createdAt,
          'updatedAt': model.updatedAt
        });
    return parseRow(r.first);
  }
}
