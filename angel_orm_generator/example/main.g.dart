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
      table.varChar('unique_id')..unique();
      table.varChar('first_name');
      table.varChar('last_name');
      table.declare('salary', ColumnType('decimal'));
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
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
      'unique_id',
      'first_name',
      'last_name',
      'salary',
      'created_at',
      'updated_at'
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
        id: row[0].toString(),
        uniqueId: (row[1] as String),
        firstName: (row[2] as String),
        lastName: (row[3] as String),
        salary: double.tryParse(row[4].toString()),
        createdAt: (row[5] as DateTime),
        updatedAt: (row[6] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class EmployeeQueryWhere extends QueryWhere {
  EmployeeQueryWhere(EmployeeQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        uniqueId = StringSqlExpressionBuilder(query, 'unique_id'),
        firstName = StringSqlExpressionBuilder(query, 'first_name'),
        lastName = StringSqlExpressionBuilder(query, 'last_name'),
        salary = NumericSqlExpressionBuilder<double>(query, 'salary'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final StringSqlExpressionBuilder uniqueId;

  final StringSqlExpressionBuilder firstName;

  final StringSqlExpressionBuilder lastName;

  final NumericSqlExpressionBuilder<double> salary;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, uniqueId, firstName, lastName, salary, createdAt, updatedAt];
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
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Employee model) {
    uniqueId = model.uniqueId;
    firstName = model.firstName;
    lastName = model.lastName;
    salary = model.salary;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Employee extends _Employee {
  Employee(
      {this.id,
      this.uniqueId,
      this.firstName,
      this.lastName,
      this.salary,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final String uniqueId;

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
      String uniqueId,
      String firstName,
      String lastName,
      double salary,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Employee(
        id: id ?? this.id,
        uniqueId: uniqueId ?? this.uniqueId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        salary: salary ?? this.salary,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Employee &&
        other.id == id &&
        other.uniqueId == uniqueId &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.salary == salary &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects(
        [id, uniqueId, firstName, lastName, salary, createdAt, updatedAt]);
  }

  @override
  String toString() {
    return "Employee(id=$id, uniqueId=$uniqueId, firstName=$firstName, lastName=$lastName, salary=$salary, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return EmployeeSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const EmployeeSerializer employeeSerializer = const EmployeeSerializer();

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
    return new Employee(
        id: map['id'] as String,
        uniqueId: map['unique_id'] as String,
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

  static Map<String, dynamic> toMap(_Employee model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'unique_id': model.uniqueId,
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
    uniqueId,
    firstName,
    lastName,
    salary,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String uniqueId = 'unique_id';

  static const String firstName = 'first_name';

  static const String lastName = 'last_name';

  static const String salary = 'salary';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
