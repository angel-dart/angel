// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.order;

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class OrderMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('orders', (table) {
      table.serial('id')..primaryKey();
      table.integer('employee_id');
      table.timeStamp('order_date');
      table.integer('shipper_id');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.integer('customer_id').references('customers', 'id');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('orders');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class OrderQuery extends Query<Order, OrderQueryWhere> {
  OrderQuery() {
    _where = new OrderQueryWhere(this);
    leftJoin('customers', 'customer_id', 'id',
        additionalFields: const ['created_at', 'updated_at']);
  }

  @override
  final OrderQueryValues values = new OrderQueryValues();

  OrderQueryWhere _where;

  @override
  get tableName {
    return 'orders';
  }

  @override
  get fields {
    return const [
      'id',
      'customer_id',
      'employee_id',
      'order_date',
      'shipper_id',
      'created_at',
      'updated_at'
    ];
  }

  @override
  OrderQueryWhere get where {
    return _where;
  }

  @override
  OrderQueryWhere newWhereClause() {
    return new OrderQueryWhere(this);
  }

  static Order parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Order(
        id: row[0].toString(),
        employeeId: (row[2] as int),
        orderDate: (row[3] as DateTime),
        shipperId: (row[4] as int),
        createdAt: (row[5] as DateTime),
        updatedAt: (row[6] as DateTime));
    if (row.length > 7) {
      model = model.copyWith(
          customer: CustomerQuery.parseRow(row.skip(7).toList()));
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class OrderQueryWhere extends QueryWhere {
  OrderQueryWhere(OrderQuery query)
      : id = new NumericSqlExpressionBuilder<int>(query, 'id'),
        customerId = new NumericSqlExpressionBuilder<int>(query, 'customer_id'),
        employeeId = new NumericSqlExpressionBuilder<int>(query, 'employee_id'),
        orderDate = new DateTimeSqlExpressionBuilder(query, 'order_date'),
        shipperId = new NumericSqlExpressionBuilder<int>(query, 'shipper_id'),
        createdAt = new DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = new DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final NumericSqlExpressionBuilder<int> customerId;

  final NumericSqlExpressionBuilder<int> employeeId;

  final DateTimeSqlExpressionBuilder orderDate;

  final NumericSqlExpressionBuilder<int> shipperId;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

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

class OrderQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  int get customerId {
    return (values['customer_id'] as int);
  }

  set customerId(int value) => values['customer_id'] = value;
  int get employeeId {
    return (values['employee_id'] as int);
  }

  set employeeId(int value) => values['employee_id'] = value;
  DateTime get orderDate {
    return (values['order_date'] as DateTime);
  }

  set orderDate(DateTime value) => values['order_date'] = value;
  int get shipperId {
    return (values['shipper_id'] as int);
  }

  set shipperId(int value) => values['shipper_id'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Order model) {
    values.addAll({
      'employee_id': model.employeeId,
      'order_date': model.orderDate,
      'shipper_id': model.shipperId,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
    if (model.customer != null) {
      values['customer_id'] = int.parse(model.customer.id);
    }
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Order extends _Order {
  Order(
      {this.id,
      this.customer,
      this.employeeId,
      this.orderDate,
      this.shipperId,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final Customer customer;

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
      Customer customer,
      int employeeId,
      DateTime orderDate,
      int shipperId,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Order(
        id: id ?? this.id,
        customer: customer ?? this.customer,
        employeeId: employeeId ?? this.employeeId,
        orderDate: orderDate ?? this.orderDate,
        shipperId: shipperId ?? this.shipperId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Order &&
        other.id == id &&
        other.customer == customer &&
        other.employeeId == employeeId &&
        other.orderDate == orderDate &&
        other.shipperId == shipperId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects(
        [id, customer, employeeId, orderDate, shipperId, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return OrderSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class OrderSerializer {
  static Order fromMap(Map map) {
    return new Order(
        id: map['id'] as String,
        customer: map['customer'] != null
            ? CustomerSerializer.fromMap(map['customer'] as Map)
            : null,
        employeeId: map['employee_id'] as int,
        orderDate: map['order_date'] != null
            ? (map['order_date'] is DateTime
                ? (map['order_date'] as DateTime)
                : DateTime.parse(map['order_date'].toString()))
            : null,
        shipperId: map['shipper_id'] as int,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null);
  }

  static Map<String, dynamic> toMap(_Order model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'customer': CustomerSerializer.toMap(model.customer),
      'employee_id': model.employeeId,
      'order_date': model.orderDate?.toIso8601String(),
      'shipper_id': model.shipperId,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class OrderFields {
  static const List<String> allFields = const <String>[
    id,
    customer,
    employeeId,
    orderDate,
    shipperId,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String customer = 'customer';

  static const String employeeId = 'employee_id';

  static const String orderDate = 'order_date';

  static const String shipperId = 'shipper_id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
