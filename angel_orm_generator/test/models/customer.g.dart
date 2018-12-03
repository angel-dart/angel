// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.customer;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class CustomerQuery extends Query<Customer, CustomerQueryWhere> {
  @override
  final CustomerQueryWhere where = new CustomerQueryWhere();

  @override
  get tableName {
    return 'customers';
  }

  @override
  get fields {
    return CustomerFields.allFields;
  }

  @override
  deserialize(List row) {
    return new Customer(
        id: row[0].toString(),
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime));
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
