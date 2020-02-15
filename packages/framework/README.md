# angel_framework

[![Pub](https://img.shields.io/pub/v/angel_framework.svg)](https://pub.dartlang.org/packages/angel_framework)
[![build status](https://travis-ci.org/angel-dart/framework.svg)](https://travis-ci.org/angel-dart/framework)

A high-powered HTTP server with support for dependency injection, sophisticated routing and more.

This is the core of the [Angel](https://github.com/angel-dart/angel) framework.
To build real-world applications, please see the [homepage](https://angel-dart.dev).

```dart
import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';

main() async {
    var app = Angel(reflector: MirrorsReflector());

    // Index route. Returns JSON.
    app.get('/', (req, res) => res.write('Welcome to Angel!'));
  
    // Accepts a URL like /greet/foo or /greet/bob.
    app.get(
      '/greet/:name',
      (req, res) {
        var name = req.params['name'];
        res
          ..write('Hello, $name!')
          ..close();
      },
    );
    
    // Pattern matching - only call this handler if the query value of `name` equals 'emoji'.
    app.get(
      '/greet',
      ioc((@Query('name', match: 'emoji') String name) => '😇🔥🔥🔥'),
    );
    
    // Handle any other query value of `name`.
    app.get(
      '/greet',
      ioc((@Query('name') String name) => 'Hello, $name!'),
    );
    
    // Simple fallback to throw a 404 on unknown paths.
    app.fallback((req, res) {
      throw AngelHttpException.notFound(
        message: 'Unknown path: "${req.uri.path}"',
      );
    });

    var http = AngelHttp(app);
    var server = await http.startServer('127.0.0.1', 3000);
    var url = 'http://${server.address.address}:${server.port}';
    print('Listening at $url');
    print('Visit these pages to see Angel in action:');
    print('* $url/greet/bob');
    print('* $url/greet/?name=emoji');
    print('* $url/greet/?name=jack');
    print('* $url/nonexistent_page');
}
```
