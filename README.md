# static
[![Pub](https://img.shields.io/pub/v/angel_static.svg)](https://pub.dartlang.org/packages/angel_static)
[![build status](https://travis-ci.org/angel-dart/static.svg?branch=master)](https://travis-ci.org/angel-dart/static)

Static server infrastructure for Angel.

*Can also handle `Range` requests now, making it suitable for media streaming, ex. music, video, etc.*

# Installation
In `pubspec.yaml`:

```yaml
dependencies:
    angel_static: ^2.0.0-alpha
```

# Usage
To serve files from a directory, you need to create a `VirtualDirectory`.
Keep in mind that `angel_static` uses `package:file` instead of `dart:io`.

```dart
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_static/angel_static.dart';
import 'package:file/local.dart';

main() async {
  var app = Angel();
  var fs = const LocalFileSystem();

  // Normal static server
  var vDir = VirtualDirectory(app, fs, source: Directory('./public'));

  // Send Cache-Control, ETag, etc. as well
  var vDir = CachingVirtualDirectory(app, fs, source: Directory('./public'));

  // Mount the VirtualDirectory's request handler
  app.fallback(vDir.handleRequest);

  // Start your server!!!
  await AngelHttp(app).startServer();
}
```

# Push State
`VirtualDirectory` also exposes a `pushState` method that returns a
request handler that serves the file at a given path as a fallback, unless
the user is requesting that file. This can be very useful for SPA's.

```dart
// Create VirtualDirectory as well
var vDir = CachingVirtualDirectory(...);

// Mount it
app.fallback(vDir.handleRequest);

// Fallback to index.html on 404
app.fallback(vDir.pushState('index.html'));
```

# Options
The `VirtualDirectory` API accepts a few named parameters:
- **source**: A `Directory` containing the files to be served. If left null, then Angel will serve either from `web` (in development) or
    `build/web` (in production), depending on your `ANGEL_ENV`.
- **indexFileNames**: A `List<String>` of filenames that should be served as index pages. Default is `['index.html']`.
- **publicPath**: To serve index files, you need to specify the virtual path under which
    angel_static is serving your files. If you are not serving static files at the site root,
    please include this.
- **callback**: Runs before sending a file to a client. Use this to set headers, etc. If it returns anything other than `null` or `true`,
then the callback's result will be sent to the user, instead of the file contents.