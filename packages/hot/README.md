# hot
[![Pub](https://img.shields.io/pub/v/angel_hot.svg)](https://pub.dartlang.org/packages/angel_hot)

![Screenshot of terminal](screenshots/screenshot.png)

Supports *hot reloading* of Angel servers on file changes. This is faster and
more reliable than merely reactively restarting a `Process`.

This package only works with the [Angel framework](https://github.com/angel-dart/angel).

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  angel_framework: ^2.0.0-alpha
  angel_hot: ^2.0.0
```

# Usage
This package is dependent on the Dart VM service, so you *must* run
Dart with the `--observe` (or `--enable-vm-service`) argument!!!

Usage is fairly simple. Pass a function that creates an `Angel` server, along with a collection of paths
to watch, to the `HotReloader` constructor. The rest is history!!!

The recommended pattern is to only use hot-reloading in your application entry point. Create your `Angel` instance
within a separate function, conventionally named `createServer`. 

**Using this in production mode is not recommended, unless you are
specifically intending for a "hot code push" in production..**

You can watch:
  * Files
  * Directories
  * Globs
  * URI's
  * `package:` URI's
  
```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_hot/angel_hot.dart';
import 'package:logging/logging.dart';
import 'src/foo.dart';

main() async {
  var hot = new HotReloader(createServer, [
    new Directory('src'),
    new Directory('src'),
    'main.dart',
    Uri.parse('package:angel_hot/angel_hot.dart')
  ]);
  await hot.startServer('127.0.0.1', 3000);
}

Future<Angel> createServer() async {
  var app = new Angel()..serializer = json.encode;

  // Edit this line, and then refresh the page in your browser!
  app.get('/', (req, res) => {'hello': 'hot world!'});
  app.get('/foo', (req, res) => new Foo(bar: 'baz'));

  app.fallback((req, res) => throw new AngelHttpException.notFound());

  app.encoders.addAll({
    'gzip': gzip.encoder,
    'deflate': zlib.encoder,
  });

  app.logger = new Logger('angel')
    ..onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) {
        print(rec.error);
        print(rec.stackTrace);
      }
    });

  return app;
}
```
