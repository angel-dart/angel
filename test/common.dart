class Todo {
  String title;
  bool completed;

  Todo({this.title, this.completed: false});

  Map toJson() {
    return {'title': title, 'completed': completed == true};
  }
}
