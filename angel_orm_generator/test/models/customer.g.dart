// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.customer;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Customer extends _Customer {
  @override
  String id;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Customer({this.id, this.createdAt, this.updatedAt});

  factory Customer.fromJson(Map data) {
    return new Customer(
        id: data['id'],
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
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Customer parse(Map map) => new Customer.fromJson(map);

  Customer clone() {
    return new Customer.fromJson(toJson());
  }
}
