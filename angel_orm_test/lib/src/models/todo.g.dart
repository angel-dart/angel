// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class TodoMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('todos', (table) {
      table.serial('id')..primaryKey();
      table.varChar('text');
      table.boolean('is_complete');
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
    return const ['id', 'text', 'is_complete', 'created_at', 'updated_at'];
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
        text: (row[1] as String),
        isComplete: (row[2] as bool),
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
        text = StringSqlExpressionBuilder(query, 'text'),
        isComplete = BooleanSqlExpressionBuilder(query, 'is_complete'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final StringSqlExpressionBuilder text;

  final BooleanSqlExpressionBuilder isComplete;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, text, isComplete, createdAt, updatedAt];
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
  String get text {
    return (values['text'] as String);
  }

  set text(String value) => values['text'] = value;
  bool get isComplete {
    return (values['is_complete'] as bool);
  }

  set isComplete(bool value) => values['is_complete'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Todo model) {
    text = model.text;
    isComplete = model.isComplete;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Todo extends _Todo {
  Todo({this.id, this.text, this.isComplete, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final String text;

  @override
  final bool isComplete;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Todo copyWith(
      {String id,
      String text,
      bool isComplete,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Todo(
        id: id ?? this.id,
        text: text ?? this.text,
        isComplete: isComplete ?? this.isComplete,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Todo &&
        other.id == id &&
        other.text == text &&
        other.isComplete == isComplete &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, text, isComplete, createdAt, updatedAt]);
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
    return new Todo(
        id: map['id'] as String,
        text: map['text'] as String,
        isComplete: map['is_complete'] as bool,
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
    return {
      'id': model.id,
      'text': model.text,
      'is_complete': model.isComplete,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class TodoFields {
  static const List<String> allFields = <String>[
    id,
    text,
    isComplete,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String text = 'text';

  static const String isComplete = 'is_complete';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
