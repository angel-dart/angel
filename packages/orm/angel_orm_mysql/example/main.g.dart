// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class TodoMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('todos', (table) {
      table.serial('id')..primaryKey();
      table.boolean('is_complete')..defaultsTo(false);
      table.varChar('text');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('todos');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class TodoQuery extends Query<Todo, TodoQueryWhere> {
  TodoQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = TodoQueryWhere(this);
  }

  @override
  final TodoQueryValues values = TodoQueryValues();

  TodoQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'todos';
  }

  @override
  get fields {
    return const ['id', 'is_complete', 'text', 'created_at', 'updated_at'];
  }

  @override
  TodoQueryWhere get where {
    return _where;
  }

  @override
  TodoQueryWhere newWhereClause() {
    return TodoQueryWhere(this);
  }

  static Todo parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Todo(
        id: row[0].toString(),
        isComplete: (row[1] as bool),
        text: (row[2] as String),
        createdAt: (row[3] as DateTime),
        updatedAt: (row[4] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class TodoQueryWhere extends QueryWhere {
  TodoQueryWhere(TodoQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        isComplete = BooleanSqlExpressionBuilder(query, 'is_complete'),
        text = StringSqlExpressionBuilder(query, 'text'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final BooleanSqlExpressionBuilder isComplete;

  final StringSqlExpressionBuilder text;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, isComplete, text, createdAt, updatedAt];
  }
}

class TodoQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  bool get isComplete {
    return (values['is_complete'] as bool);
  }

  set isComplete(bool value) => values['is_complete'] = value;
  String get text {
    return (values['text'] as String);
  }

  set text(String value) => values['text'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Todo model) {
    isComplete = model.isComplete;
    text = model.text;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Todo extends _Todo {
  Todo(
      {this.id,
      this.isComplete = false,
      this.text,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final bool isComplete;

  @override
  final String text;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Todo copyWith(
      {String id,
      bool isComplete,
      String text,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Todo(
        id: id ?? this.id,
        isComplete: isComplete ?? this.isComplete,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Todo &&
        other.id == id &&
        other.isComplete == isComplete &&
        other.text == text &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, isComplete, text, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return TodoSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class TodoSerializer {
  static Todo fromMap(Map map) {
    if (map['is_complete'] == null) {
      throw new FormatException(
          "Missing required field 'is_complete' on Todo.");
    }

    return new Todo(
        id: map['id'] as String,
        isComplete: map['is_complete'] as bool ?? false,
        text: map['text'] as String,
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

  static Map<String, dynamic> toMap(_Todo model) {
    if (model == null) {
      return null;
    }
    if (model.isComplete == null) {
      throw new FormatException(
          "Missing required field 'is_complete' on Todo.");
    }

    return {
      'id': model.id,
      'is_complete': model.isComplete,
      'text': model.text,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class TodoFields {
  static const List<String> allFields = <String>[
    id,
    isComplete,
    text,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String isComplete = 'is_complete';

  static const String text = 'text';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
