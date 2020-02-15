// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Employee extends _Employee {
  Employee(
      {this.id,
      this.firstName,
      this.lastName,
      this.salary,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final String firstName;

  @override
  final String lastName;

  @override
  final double salary;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Employee copyWith(
      {String id,
      String firstName,
      String lastName,
      double salary,
      DateTime createdAt,
      DateTime updatedAt}) {
    return Employee(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        salary: salary ?? this.salary,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Employee &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.salary == salary &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, firstName, lastName, salary, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return EmployeeSerializer.toMap(this);
  }
}
