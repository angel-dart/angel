// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.order;

// **************************************************************************
// OrmGenerator
// **************************************************************************

class OrderQuery extends Query<Order, OrderQueryWhere> {
  @override
  final OrderQueryValues values = new OrderQueryValues();

  @override
  final OrderQueryWhere where = new OrderQueryWhere();

  @override
  get tableName {
    return 'orders';
  }

  @override
  get fields {
    return const [
      'id',
      'customer_id',
      'employee_id',
      'order_date',
      'shipper_id',
      'created_at',
      'updated_at'
    ];
  }

  @override
  OrderQueryWhere newWhereClause() {
    return new OrderQueryWhere();
  }

  static Order parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Order(
        id: row[0].toString(),
        customerId: (row[1] as int),
        employeeId: (row[2] as int),
        orderDate: (row[3] as DateTime),
        shipperId: (row[4] as int),
        createdAt: (row[5] as DateTime),
        updatedAt: (row[6] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class OrderQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final NumericSqlExpressionBuilder<int> customerId =
      new NumericSqlExpressionBuilder<int>('customer_id');

  final NumericSqlExpressionBuilder<int> employeeId =
      new NumericSqlExpressionBuilder<int>('employee_id');

  final DateTimeSqlExpressionBuilder orderDate =
      new DateTimeSqlExpressionBuilder('order_date');

  final NumericSqlExpressionBuilder<int> shipperId =
      new NumericSqlExpressionBuilder<int>('shipper_id');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [
      id,
      customerId,
      employeeId,
      orderDate,
      shipperId,
      createdAt,
      updatedAt
    ];
  }
}

class OrderQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  int get customerId {
    return (values['customer_id'] as int);
  }

  void set customerId(int value) => values['customer_id'] = value;
  int get employeeId {
    return (values['employee_id'] as int);
  }

  void set employeeId(int value) => values['employee_id'] = value;
  DateTime get orderDate {
    return (values['order_date'] as DateTime);
  }

  void set orderDate(DateTime value) => values['order_date'] = value;
  int get shipperId {
    return (values['shipper_id'] as int);
  }

  void set shipperId(int value) => values['shipper_id'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  void set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  void set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Order model) {
    values.addAll({
      'customer_id': model.customerId,
      'employee_id': model.employeeId,
      'order_date': model.orderDate,
      'shipper_id': model.shipperId,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Order extends _Order {
  Order(
      {this.id,
      this.customerId,
      this.employeeId,
      this.orderDate,
      this.shipperId,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final int customerId;

  @override
  final int employeeId;

  @override
  final DateTime orderDate;

  @override
  final int shipperId;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Order copyWith(
      {String id,
      int customerId,
      int employeeId,
      DateTime orderDate,
      int shipperId,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Order(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        employeeId: employeeId ?? this.employeeId,
        orderDate: orderDate ?? this.orderDate,
        shipperId: shipperId ?? this.shipperId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Order &&
        other.id == id &&
        other.customerId == customerId &&
        other.employeeId == employeeId &&
        other.orderDate == orderDate &&
        other.shipperId == shipperId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([
      id,
      customerId,
      employeeId,
      orderDate,
      shipperId,
      createdAt,
      updatedAt
    ]);
  }

  Map<String, dynamic> toJson() {
    return OrderSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class OrderSerializer {
  static Order fromMap(Map map) {
    return new Order(
        id: map['id'] as String,
        customerId: map['customer_id'] as int,
        employeeId: map['employee_id'] as int,
        orderDate: map['order_date'] != null
            ? (map['order_date'] is DateTime
                ? (map['order_date'] as DateTime)
                : DateTime.parse(map['order_date'].toString()))
            : null,
        shipperId: map['shipper_id'] as int,
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

  static Map<String, dynamic> toMap(Order model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'customer_id': model.customerId,
      'employee_id': model.employeeId,
      'order_date': model.orderDate?.toIso8601String(),
      'shipper_id': model.shipperId,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class OrderFields {
  static const List<String> allFields = const <String>[
    id,
    customerId,
    employeeId,
    orderDate,
    shipperId,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String customerId = 'customer_id';

  static const String employeeId = 'employee_id';

  static const String orderDate = 'order_date';

  static const String shipperId = 'shipper_id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
