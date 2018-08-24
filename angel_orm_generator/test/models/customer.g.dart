// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.customer;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Customer extends _Customer {
  Customer({this.id, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Customer copyWith({String id, DateTime createdAt, DateTime updatedAt}) {
    return new Customer(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Customer &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  Map<String, dynamic> toJson() {
    return CustomerSerializer.toMap(this);
  }
}
