// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

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
    return Todo(
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

  @override
  String toString() {
    return "Todo(id=$id, text=$text, isComplete=$isComplete, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return TodoSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const TodoSerializer todoSerializer = TodoSerializer();

class TodoEncoder extends Converter<Todo, Map> {
  const TodoEncoder();

  @override
  Map convert(Todo model) => TodoSerializer.toMap(model);
}

class TodoDecoder extends Converter<Map, Todo> {
  const TodoDecoder();

  @override
  Todo convert(Map map) => TodoSerializer.fromMap(map);
}

class TodoSerializer extends Codec<Todo, Map> {
  const TodoSerializer();

  @override
  get encoder => const TodoEncoder();
  @override
  get decoder => const TodoDecoder();
  static Todo fromMap(Map map) {
    return Todo(
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

// **************************************************************************
// _GraphQLGenerator
// **************************************************************************

/// Auto-generated from [Todo].
final GraphQLObjectType todoGraphQLType =
    objectType('Todo', isInterface: false, interfaces: [], fields: [
  field('id', graphQLString),
  field('text', graphQLString),
  field('is_complete', graphQLBoolean),
  field('created_at', graphQLDate),
  field('updated_at', graphQLDate),
  field('idAsInt', graphQLInt)
]);
