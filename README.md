# angel_static

![version 1.1.0-dev](https://img.shields.io/badge/version-1.1.0--dev-red.svg)
![build status](https://travis-ci.org/angel-dart/static.svg?branch=master)

Static server middleware for Angel.

# Installation
In `pubspec.yaml`:

```yaml
dependencies:
    angel_framework: ^1.0.0-dev
    angel_static: ^1.1.0-dev
```

# Usage
To serve files from a directory, your app needs to have a
`VirtualDirectory` mounted on it.

```dart
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';

main() async {
  final app = new Angel();
  
  app.mount('/virtual', new VirtualDirectory(
      source: new Directory('./foo/bar'),
      publicPath: '/virtual'));

  app.mount('/', new VirtualDirectory(source: new Directory('./public')));
  
  await app.startServer();
}
```

# Options
The `VirtualDirectory` API accepts a few named parameters:
- **source**: A `Directory` containing the files to be served. If left null, then Angel will serve either from `web` (in development) or
    `build/web` (in production), depending on your `ANGEL_ENV`.
- **indexFileNames**: A `List<String>` of filenames that should be served as index pages. Default is `['index.html']`.
- **publicPath**: To serve index files, you need to specify the virtual path under which
    angel_static is serving your files. If you are not serving static files at the site root,
    please include this.
- **debug**: Print verbose debug output.
