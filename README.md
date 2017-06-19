# angel_framework

[![Pub](https://img.shields.io/pub/v/angel_framework.svg)](https://pub.dartlang.org/packages/angel_framework)
[![build status](https://travis-ci.org/angel-dart/framework.svg)](https://travis-ci.org/angel-dart/framework)

A high-powered HTTP server with support for dependency injection, sophisticated routing and more.

This is the core of the [Angel](https://github.com/angel-dart/angel) framework.
To build real-world applications, please see the [homepage](https://angel-dart.github.io).

```dart
import 'package:angel_framework/angel_framework.dart';

main() async {
  var app = new Angel();

  app
    ..get('/hello', (req, res) {
      res.write('world!');
    })
    ..post('/date', () => new DateTime.now().toString());

  await app.startServer();
}
```
