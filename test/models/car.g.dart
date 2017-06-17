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
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Car({this.id, this.createdAt, this.updatedAt});

  factory Car.fromJson(Map data) {
    return new Car(
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

  static Car parse(Map map) => new Car.fromJson(map);
}
