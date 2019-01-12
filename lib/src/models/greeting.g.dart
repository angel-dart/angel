// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'greeting.dart';

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class GreetingMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('greetings', (table) {
      table.serial('id')..primaryKey();
      table.varChar('message');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('greetings');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class GreetingQuery extends Query<Greeting, GreetingQueryWhere> {
  GreetingQuery() {
    _where = new GreetingQueryWhere(this);
  }

  @override
  final GreetingQueryValues values = new GreetingQueryValues();

  GreetingQueryWhere _where;

  @override
  get tableName {
    return 'greetings';
  }

  @override
  get fields {
    return const ['id', 'message', 'created_at', 'updated_at'];
  }

  @override
  GreetingQueryWhere get where {
    return _where;
  }

  @override
  GreetingQueryWhere newWhereClause() {
    return new GreetingQueryWhere(this);
  }

  static Greeting parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Greeting(
        id: row[0].toString(),
        message: (row[1] as String),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class GreetingQueryWhere extends QueryWhere {
  GreetingQueryWhere(GreetingQuery query)
      : id = new NumericSqlExpressionBuilder<int>(query, 'id'),
        message = new StringSqlExpressionBuilder(query, 'message'),
        createdAt = new DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = new DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final StringSqlExpressionBuilder message;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, message, createdAt, updatedAt];
  }
}

class GreetingQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  String get message {
    return (values['message'] as String);
  }

  set message(String value) => values['message'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Greeting model) {
    values.addAll({
      'message': model.message,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Greeting extends _Greeting {
  Greeting({this.id, @required this.message, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final String message;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Greeting copyWith(
      {String id, String message, DateTime createdAt, DateTime updatedAt}) {
    return new Greeting(
        id: id ?? this.id,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Greeting &&
        other.id == id &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, message, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return GreetingSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class GreetingSerializer {
  static Greeting fromMap(Map map) {
    if (map['message'] == null) {
      throw new FormatException(
          "Missing required field 'message' on Greeting.");
    }

    return new Greeting(
        id: map['id'] as String,
        message: map['message'] as String,
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

  static Map<String, dynamic> toMap(_Greeting model) {
    if (model == null) {
      return null;
    }
    if (model.message == null) {
      throw new FormatException(
          "Missing required field 'message' on Greeting.");
    }

    return {
      'id': model.id,
      'message': model.message,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class GreetingFields {
  static const List<String> allFields = const <String>[
    id,
    message,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String message = 'message';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
