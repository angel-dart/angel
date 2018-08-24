// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.order;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class OrderSerializer {
  static Order fromMap(Map map) {
    return new Order(
        id: map['id'] as String,
        customerId: map['customer_id'] as int,
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

  static Map<String, dynamic> toMap(Order model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'customer_id': model.customerId,
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
    customerId,
    employeeId,
    orderDate,
    shipperId,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String customerId = 'customer_id';

  static const String employeeId = 'employee_id';

  static const String orderDate = 'order_date';

  static const String shipperId = 'shipper_id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
