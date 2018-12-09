// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.customer;

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class CustomerMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('customers', (table) {
      table.serial('id')..primaryKey();
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('customers');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class CustomerQuery extends Query<Customer, CustomerQueryWhere> {
  @override
  final CustomerQueryValues values = new CustomerQueryValues();

  @override
  final CustomerQueryWhere where = new CustomerQueryWhere();

  @override
  get tableName {
    return 'customers';
  }

  @override
  get fields {
    return const ['id', 'created_at', 'updated_at'];
  }

  @override
  CustomerQueryWhere newWhereClause() {
    return new CustomerQueryWhere();
  }

  static Customer parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Customer(
        id: row[0].toString(),
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class CustomerQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [id, createdAt, updatedAt];
  }
}

class CustomerQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  void set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  void set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Customer model) {
    values
        .addAll({'created_at': model.createdAt, 'updated_at': model.updatedAt});
  }
}

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

  @override
  int get hashCode {
    return hashObjects([id, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return CustomerSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class CustomerSerializer {
  static Customer fromMap(Map map) {
    return new Customer(
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
            : null);
  }

  static Map<String, dynamic> toMap(_Customer model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class CustomerFields {
  static const List<String> allFields = const <String>[
    id,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
