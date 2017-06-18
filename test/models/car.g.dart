// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.test.models.car;

// **************************************************************************
// Generator: JsonModelGenerator
// Target: class _Car
// **************************************************************************

class Car extends _Car {
  @override
  String make;

  @override
  String description;

  @override
  bool familyFriendly;

  @override
  DateTime recalledAt;

  @override
  List tires;

  Car(
      {this.make,
      this.description,
      this.familyFriendly,
      this.recalledAt,
      this.tires});

  factory Car.fromJson(Map data) {
    return new Car(
        make: data['make'],
        description: data['description'],
        familyFriendly: data['familyFriendly'],
        recalledAt: data['recalledAt'] is DateTime
            ? data['recalledAt']
            : (data['recalledAt'] is String
                ? DateTime.parse(data['recalledAt'])
                : null),
        tires: data['tires']);
  }

  Map<String, dynamic> toJson() => {
        'make': make,
        'description': description,
        'familyFriendly': familyFriendly,
        'recalledAt': recalledAt == null ? null : recalledAt.toIso8601String(),
        'tires': tires
      };

  static Car parse(Map map) => new Car.fromJson(map);
}
