import 'package:angel_client/io.dart';
import 'package:angel_poll/angel_poll.dart';

main() {
  var app = new Rest('http://localhost:3000');

  var todos = new ServiceList(
    new PollingService(
      // Typically, you'll pass a REST-based service instance here.
      app.service('api/todos'),

      // `index` called every 5 seconds
      const Duration(seconds: 5),
    ),
  );

  todos.onChange.listen((_) {
    // Something happened here.
    // Maybe an item was created, modified, etc.
  });
}
