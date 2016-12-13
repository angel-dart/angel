# angel_client

[![pub 1.0.0-dev+21](https://img.shields.io/badge/pub-1.0.0--dev+21-red.svg)](https://pub.dartlang.org/packages/angel_client)
![build status](https://travis-ci.org/angel-dart/client.svg)

Client library for the Angel framework.

# Isomorphic
The REST client can run in the browser or on the command-line.

# Usage
This library provides the same API as an Angel server.

```dart
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

The CLI client also supports reflection via `json_god`. There is no need to work with Maps;
you can use the same class on the client and the server.

```dart
class Todo extends Model {
  String text;

  Todo({String this.text});
}

bar() async {
  // By the next release, this will just be:
  // app.service<Todo>("todos")
  Service Todos = app.service("todos", type: Todo);
  List<Todo> todos = await Todos.index();

  print(todos.length);
}
```

Just like on the server, services support `index`, `read`, `create`, `modify`, `update` and
`remove`.
