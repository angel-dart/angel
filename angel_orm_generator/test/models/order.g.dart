// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.order;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class OrderQuery extends Query<Order, OrderQueryWhere> {
  @override
  final OrderQueryWhere where = new OrderQueryWhere();

  @override
  get tableName {
    return 'orders';
  }

  @override
  get fields {
    return const [
      'id',
      'customerId',
      'employeeId',
      'orderDate',
      'shipperId',
      'createdAt',
      'updatedAt'
    ];
  }

  @override
  deserialize(List row) {
    return new Order(
        id: (row[0] as String),
        customerId: (row[0] as int),
        employeeId: (row[0] as int),
        orderDate: (row[0] as DateTime),
        shipperId: (row[0] as int),
        createdAt: (row[0] as DateTime),
        updatedAt: (row[0] as DateTime));
  }
}

class OrderQueryWhere extends QueryWhere {
  final StringSqlExpressionBuilder id = new StringSqlExpressionBuilder('id');

  final NumericSqlExpressionBuilder<int> customerId =
      new NumericSqlExpressionBuilder<int>('customer_id');

  final NumericSqlExpressionBuilder<int> employeeId =
      new NumericSqlExpressionBuilder<int>('employee_id');

  final DateTimeSqlExpressionBuilder orderDate =
      new DateTimeSqlExpressionBuilder('order_date');

  final NumericSqlExpressionBuilder<int> shipperId =
      new NumericSqlExpressionBuilder<int>('shipper_id');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [
      id,
      customerId,
      employeeId,
      orderDate,
      shipperId,
      createdAt,
      updatedAt
    ];
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Order extends _Order {
  Order(
      {this.id,
      this.customerId,
      this.employeeId,
      this.orderDate,
      this.shipperId,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final int customerId;

  @override
  final int employeeId;

  @override
  final DateTime orderDate;

  @override
  final int shipperId;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Order copyWith(
      {String id,
      int customerId,
      int employeeId,
      DateTime orderDate,
      int shipperId,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Order(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        employeeId: employeeId ?? this.employeeId,
        orderDate: orderDate ?? this.orderDate,
        shipperId: shipperId ?? this.shipperId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Order &&
        other.id == id &&
        other.customerId == customerId &&
        other.employeeId == employeeId &&
        other.orderDate == orderDate &&
        other.shipperId == shipperId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([
      id,
      customerId,
      employeeId,
      orderDate,
      shipperId,
      createdAt,
      updatedAt
    ]);
  }

  Map<String, dynamic> toJson() {
    return OrderSerializer.toMap(this);
  }
}
