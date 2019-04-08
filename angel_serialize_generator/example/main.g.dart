// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Todo extends _Todo {
  Todo({this.text, this.completed});

  @override
  final String text;

  @override
  final bool completed;

  Todo copyWith({String text, bool completed}) {
    return new Todo(
        text: text ?? this.text, completed: completed ?? this.completed);
  }

  bool operator ==(other) {
    return other is _Todo && other.text == text && other.completed == completed;
  }

  @override
  int get hashCode {
    return hashObjects([text, completed]);
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
        text: map['text'] as String, completed: map['completed'] as bool);
  }

  static Map<String, dynamic> toMap(_Todo model) {
    if (model == null) {
      return null;
    }
    return {'text': model.text, 'completed': model.completed};
  }
}

abstract class TodoFields {
  static const List<String> allFields = <String>[text, completed];

  static const String text = 'text';

  static const String completed = 'completed';
}
