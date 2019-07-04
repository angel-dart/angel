// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class EmployeeSerializer {
  static Employee fromMap(Map map) {
    return Employee(
        id: map['id'] as String,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        salary: map['salary'] as double,
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

  static Map<String, dynamic> toMap(Employee model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'first_name': model.firstName,
      'last_name': model.lastName,
      'salary': model.salary,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class EmployeeFields {
  static const List<String> allFields = <String>[
    id,
    firstName,
    lastName,
    salary,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String firstName = 'first_name';

  static const String lastName = 'last_name';

  static const String salary = 'salary';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
