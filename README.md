# angel_framework

[![pub 1.0.2+5](https://img.shields.io/badge/pub-1.0.2+5-brightgreen.svg)](https://pub.dartlang.org/packages/angel_framework)
[![build status](https://travis-ci.org/angel-dart/framework.svg)](https://travis-ci.org/angel-dart/framework)

A high-powered HTTP server with support for dependency injection, sophisticated routing and more.

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
