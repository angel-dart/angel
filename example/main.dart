import 'package:angel_model/angel_model.dart';

void main() {
  var todo = Todo(id: '34', isComplete: false);
  print(todo.idAsInt == 34);
}

class Todo extends Model {
  String text;

  bool isComplete;

  Todo(
      {String id,
      this.text,
      this.isComplete,
      DateTime createdAt,
      DateTime updatedAt})
      : super(id: id, createdAt: createdAt, updatedAt: updatedAt);
}
