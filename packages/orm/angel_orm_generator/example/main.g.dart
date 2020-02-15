// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class EmployeeMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('employees', (table) {
      table.serial('id')..primaryKey();
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.varChar('unique_id');
      table.varChar('first_name');
      table.varChar('last_name');
      table.declare('salary', ColumnType('decimal'));
    });
  }

  @override
  down(Schema schema) {
    schema.drop('employees');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class EmployeeQuery extends Query<Employee, EmployeeQueryWhere> {
  EmployeeQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = EmployeeQueryWhere(this);
  }

  @override
  final EmployeeQueryValues values = EmployeeQueryValues();

  EmployeeQueryWhere _where;

  @override
  get casts {
    return {'salary': 'text'};
  }

  @override
  get tableName {
    return 'employees';
  }

  @override
  get fields {
    return const [
      'id',
      'created_at',
      'updated_at',
      'unique_id',
      'first_name',
      'last_name',
      'salary'
    ];
  }

  @override
  EmployeeQueryWhere get where {
    return _where;
  }

  @override
  EmployeeQueryWhere newWhereClause() {
    return EmployeeQueryWhere(this);
  }

  static Employee parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Employee(
        id: (row[0] as String),
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime),
        uniqueId: (row[3] as String),
        firstName: (row[4] as String),
        lastName: (row[5] as String),
        salary: double.tryParse(row[6].toString()));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class EmployeeQueryWhere extends QueryWhere {
  EmployeeQueryWhere(EmployeeQuery query)
      : id = StringSqlExpressionBuilder(query, 'id'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at'),
        uniqueId = StringSqlExpressionBuilder(query, 'unique_id'),
        firstName = StringSqlExpressionBuilder(query, 'first_name'),
        lastName = StringSqlExpressionBuilder(query, 'last_name'),
        salary = NumericSqlExpressionBuilder<double>(query, 'salary');

  final StringSqlExpressionBuilder id;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  final StringSqlExpressionBuilder uniqueId;

  final StringSqlExpressionBuilder firstName;

  final StringSqlExpressionBuilder lastName;

  final NumericSqlExpressionBuilder<double> salary;

  @override
  get expressionBuilders {
    return [id, createdAt, updatedAt, uniqueId, firstName, lastName, salary];
  }
}

class EmployeeQueryValues extends MapQueryValues {
  @override
  get casts {
    return {'salary': 'decimal'};
  }

  String get id {
    return (values['id'] as String);
  }

  set id(String value) => values['id'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  String get uniqueId {
    return (values['unique_id'] as String);
  }

  set uniqueId(String value) => values['unique_id'] = value;
  String get firstName {
    return (values['first_name'] as String);
  }

  set firstName(String value) => values['first_name'] = value;
  String get lastName {
    return (values['last_name'] as String);
  }

  set lastName(String value) => values['last_name'] = value;
  double get salary {
    return double.tryParse((values['salary'] as String));
  }

  set salary(double value) => values['salary'] = value.toString();
  void copyFrom(Employee model) {
    id = model.id;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    uniqueId = model.uniqueId;
    firstName = model.firstName;
    lastName = model.lastName;
    salary = model.salary;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Employee extends _Employee {
  Employee(
      {this.id,
      this.createdAt,
      this.updatedAt,
      this.uniqueId,
      this.firstName,
      this.lastName,
      this.salary});

  /// A unique identifier corresponding to this item.
  @override
  String id;

  /// The time at which this item was created.
  @override
  DateTime createdAt;

  /// The last time at which this item was updated.
  @override
  DateTime updatedAt;

  @override
  String uniqueId;

  @override
  final String firstName;

  @override
  final String lastName;

  @override
  final double salary;

  Employee copyWith(
      {String id,
      DateTime createdAt,
      DateTime updatedAt,
      String uniqueId,
      String firstName,
      String lastName,
      double salary}) {
    return Employee(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        uniqueId: uniqueId ?? this.uniqueId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        salary: salary ?? this.salary);
  }

  bool operator ==(other) {
    return other is _Employee &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.uniqueId == uniqueId &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.salary == salary;
  }

  @override
  int get hashCode {
    return hashObjects(
        [id, createdAt, updatedAt, uniqueId, firstName, lastName, salary]);
  }

  @override
  String toString() {
    return "Employee(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, uniqueId=$uniqueId, firstName=$firstName, lastName=$lastName, salary=$salary)";
  }

  Map<String, dynamic> toJson() {
    return EmployeeSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const EmployeeSerializer employeeSerializer = EmployeeSerializer();

class EmployeeEncoder extends Converter<Employee, Map> {
  const EmployeeEncoder();

  @override
  Map convert(Employee model) => EmployeeSerializer.toMap(model);
}

class EmployeeDecoder extends Converter<Map, Employee> {
  const EmployeeDecoder();

  @override
  Employee convert(Map map) => EmployeeSerializer.fromMap(map);
}

class EmployeeSerializer extends Codec<Employee, Map> {
  const EmployeeSerializer();

  @override
  get encoder => const EmployeeEncoder();
  @override
  get decoder => const EmployeeDecoder();
  static Employee fromMap(Map map) {
    return Employee(
        id: map['id'] as String,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null,
        uniqueId: map['unique_id'] as String,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        salary: map['salary'] as double);
  }

  static Map<String, dynamic> toMap(_Employee model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'unique_id': model.uniqueId,
      'first_name': model.firstName,
      'last_name': model.lastName,
      'salary': model.salary
    };
  }
}

abstract class EmployeeFields {
  static const List<String> allFields = <String>[
    id,
    createdAt,
    updatedAt,
    uniqueId,
    firstName,
    lastName,
    salary
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String uniqueId = 'unique_id';

  static const String firstName = 'first_name';

  static const String lastName = 'last_name';

  static const String salary = 'salary';
}
