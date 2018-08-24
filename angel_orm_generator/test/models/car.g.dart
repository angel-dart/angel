// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.car;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Car extends _Car {
  Car(
      {this.id,
      this.make,
      this.description,
      this.familyFriendly,
      this.recalledAt,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final String make;

  @override
  final String description;

  @override
  final bool familyFriendly;

  @override
  final DateTime recalledAt;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Car copyWith(
      {String id,
      String make,
      String description,
      bool familyFriendly,
      DateTime recalledAt,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Car(
        id: id ?? this.id,
        make: make ?? this.make,
        description: description ?? this.description,
        familyFriendly: familyFriendly ?? this.familyFriendly,
        recalledAt: recalledAt ?? this.recalledAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Car &&
        other.id == id &&
        other.make == make &&
        other.description == description &&
        other.familyFriendly == familyFriendly &&
        other.recalledAt == recalledAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  Map<String, dynamic> toJson() {
    return CarSerializer.toMap(this);
  }
}
