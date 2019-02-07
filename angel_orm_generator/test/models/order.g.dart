// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.order;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class OrderQuery extends Query<Order, OrderQueryWhere> {
  OrderQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = OrderQueryWhere(this);
  }

  @override
  final OrderQueryValues values = OrderQueryValues();

  OrderQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'orders';
  }

  @override
  get fields {
    return const ['id'];
  }

  @override
  OrderQueryWhere get where {
    return _where;
  }

  @override
  OrderQueryWhere newWhereClause() {
    return OrderQueryWhere(this);
  }

  static Order parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Order(id: row[0].toString());
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class OrderQueryWhere extends QueryWhere {
  OrderQueryWhere(OrderQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id');

  final NumericSqlExpressionBuilder<int> id;

  @override
  get expressionBuilders {
    return [id];
  }
}

class OrderQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  void copyFrom(Order model) {}
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
  final dynamic customer;

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
      dynamic customer,
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
        customer: map['customer'] as dynamic,
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
      'customer': model.customer,
      'employee_id': model.employeeId,
      'order_date': model.orderDate?.toIso8601String(),
      'shipper_id': model.shipperId,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class OrderFields {
  static const List<String> allFields = <String>[
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
