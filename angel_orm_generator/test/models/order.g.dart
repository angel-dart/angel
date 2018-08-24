// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.order;

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

  Map<String, dynamic> toJson() {
    return OrderSerializer.toMap(this);
  }
}
