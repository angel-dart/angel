// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.order;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Order extends _Order {
  @override
  String id;

  @override
  int customerId;

  @override
  int employeeId;

  @override
  DateTime orderDate;

  @override
  int shipperId;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Order(
      {this.id,
      this.customerId,
      this.employeeId,
      this.orderDate,
      this.shipperId,
      this.createdAt,
      this.updatedAt});

  factory Order.fromJson(Map data) {
    return new Order(
        id: data['id'],
        customerId: data['customer_id'],
        employeeId: data['employee_id'],
        orderDate: data['order_date'] is DateTime
            ? data['order_date']
            : (data['order_date'] is String
                ? DateTime.parse(data['order_date'])
                : null),
        shipperId: data['shipper_id'],
        createdAt: data['created_at'] is DateTime
            ? data['created_at']
            : (data['created_at'] is String
                ? DateTime.parse(data['created_at'])
                : null),
        updatedAt: data['updated_at'] is DateTime
            ? data['updated_at']
            : (data['updated_at'] is String
                ? DateTime.parse(data['updated_at'])
                : null));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'employee_id': employeeId,
        'order_date': orderDate == null ? null : orderDate.toIso8601String(),
        'shipper_id': shipperId,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Order parse(Map map) => new Order.fromJson(map);

  Order clone() {
    return new Order.fromJson(toJson());
  }
}
