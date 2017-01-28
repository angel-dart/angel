library angel_framework.test.common;

import 'package:angel_framework/angel_framework.dart';

class Todo extends MemoryModel {
  String text;
  String over;

  Todo({String this.text, String this.over});
}

class BookService extends Service {
  @override
  index([params]) async {
    print('Book params: $params');
    
    return [
      {'foo': 'bar'}
    ];
  }
}

incrementTodoTimes(e) {
  IncrementService.TIMES++;
}

@Hooks(before: const [incrementTodoTimes])
class IncrementService extends Service {
  static int TIMES = 0;

  @override
  @Hooks(after: const [incrementTodoTimes])
  index([params]) async => [];
}
