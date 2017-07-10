// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.test.models.car;

// **************************************************************************
// Generator: JsonModelGenerator
// Target: class _Car
// **************************************************************************

class Car extends _Car {
  @override
  String id;

  @override
  String make;

  @override
  String description;

  @override
  bool familyFriendly;

  @override
  DateTime recalledAt;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Car(
      {this.id,
      this.make,
      this.description,
      this.familyFriendly,
      this.recalledAt,
      this.createdAt,
      this.updatedAt});

  factory Car.fromJson(Map data) {
    return new Car(
        id: data['id'],
        make: data['make'],
        description: data['description'],
        familyFriendly: data['family_friendly'],
        recalledAt: data['recalled_at'] is DateTime
            ? data['recalled_at']
            : (data['recalled_at'] is String
                ? DateTime.parse(data['recalled_at'])
                : null),
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
        'make': make,
        'description': description,
        'family_friendly': familyFriendly,
        'recalled_at': recalledAt == null ? null : recalledAt.toIso8601String(),
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Car parse(Map map) => new Car.fromJson(map);

  Car clone() {
    return new Car.fromJson(toJson());
  }
}
