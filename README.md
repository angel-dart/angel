# angel_static

![version 1.0.1](https://img.shields.io/badge/version-1.0.1-green.svg)
![build status](https://travis-ci.org/angel-dart/static.svg?branch=master)

Static server middleware for Angel.

# Installation
In `pubspec.yaml`:

```yaml
dependencies:
    angel_framework: ^1.0.0-dev
    angel_static: ^1.0.0
```

# Usage
As with all Angel middleware, this can be used simply via a function
call within the route declaration, or registered under a name and invoked
under that same name.

```dart
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';

main() async {
    Angel angel = new Angel();
    angel.registerMiddleware("static", serveStatic());
    angel.get('/virtual*', serveStatic(virtualRoot: '/virtual'));
    angel.get("*", "static");

    await angel.startServer(InternetAddress.LOOPBACK_IP_V4, 8080);
}
```

# Options
`serveStatic` accepts two named parameters.
- **sourceDirectory**: A `Directory` containing the files to be served. If left null, then Angel will serve either from `web` (in development) or
    `build/web` (in production), depending on your `ANGEL_ENV`.
- **indexFileNames**: A `List<String` of filenames that should be served as index pages. Default is `['index.html']`.
- **virtualRoot**: To serve index files, you need to specify the virtual path under which
    angel_static is serving your files. If you are not serving static files at the site root,
    please include this.
