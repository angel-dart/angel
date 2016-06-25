# angel_client
Client library for the Angel framework.

# Isomorphic
The REST client can run in the browser or on the command-line.

# Usage
This library provides the same API as an Angel server.

```dart
// Import this file to import symbols "Angel" and "Service"
import 'package:angel_cli/shared.dart';
// Choose one or the other, depending on platform
import 'package:angel_client/cli.dart';
import 'package:angel_client/browser.dart';

main() async {
  Angel app = new Rest("http://localhost:3000", new BrowserClient());
}
```

You can call `service` to receive an instance of `Service`, which acts as a client to a
service on the server at the given path (say that five times fast!).

```dart
foo() async {
  Service Todos = app.service("todos");
  List<Map> todos = await Todos.index();

  print(todos.length);
}
```

The REST client also supports reflection via `json_god`. There is no need to work with Maps;
you can use the same class on the client and the server.

```dart
class Todo extends Model {
  String text;

  Todo({String this.text});
}

bar() async {
  Service Todos = app.service("todos", type: Todo);
  List<Todo> todos = await Todos.index();

  print(todos.length);
}
```

Just like on the server, services support `index`, `read`, `create`, `modify`, `update` and
`remove`.