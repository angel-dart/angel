# static

[![Pub](https://img.shields.io/pub/v/angel_static.svg)](https://pub.dartlang.org/packages/angel_static)
[![build status](https://travis-ci.org/angel-dart/static.svg?branch=master)](https://travis-ci.org/angel-dart/static)

Static server middleware for Angel.

# Installation
In `pubspec.yaml`:

```yaml
dependencies:
    angel_static: ^1.2.0
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

  // Normal static server
  await app.configure(new VirtualDirectory(source: new Directory('./public')));

  // Send Cache-Control, ETag, etc. as well
  await app.configure(new CachingVirtualDirectory(source: new Directory('./public')));

  await app.startServer();
}
```

# Push State Example
```dart
var vDir = new VirtualDirectory(...);
var indexFile = new File.fromUri(vDir.source.uri.resolve('index.html'));

app.after.add((req, ResponseContext res) {
  // Fallback to index.html on 404
  return res.sendFile(indexFile);
});
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
- **callback**: Runs before sending a file to a client. Use this to set headers, etc. If it returns anything other than `null` or `true`,
then the callback's result will be sent to the user, instead of the file contents.
- **streamToIO**: If set to `true`, files will be streamed to `res.io`, instead of added to `res.buffer`.. Default is `false`.

# Transformers
`angel_static` now supports *transformers*. Similarly to `pub serve`, or `package:build`, these
let you dynamically compile assets before sending them to users. For example, in development, you might
consider using transformers to compile CSS files, or to even replace `pub serve`.
Transformers are supported by `VirtualDirectory` and `CachingVirtualDirectory`.

To create a transformer:
```dart
class MinifierTransformer {
  /// Use this to declare outputs, and indicate if your transformer
  /// will compile a file.
  @override
  FileInfo declareOutput(FileInfo file) {
    // For example, we might only want to minify HTML files.
    if (!file.extensions.endsWith('.min.html'))
      return null;
    else return file.changeExtension('.min.html');
  }
  
  /// Actually compile the asset here.
  @override
  FutureOr<FileInfo> transform(FileInfo file) async {
    return file
      .changeExtension('.min.html')
      .changeContent(
        file.content
          .transform(UTF8.decoder)
          .transform(const LineSplitter()
          .transform(UTF8.encoder))
      );
  }
}
```

To use it:
```dart
configureServer(Angel app) async {
  var vDir = new CachingVirtualDirectory(
    transformers: [new MinifierTransformer()]
  );
  await app.configure(vDir);
  
  // It is suggested that you await `transformersLoaded`.
  // Otherwise, you may receive 404's on paths that should send a compiled asset.
  await vDir.transformersLoaded;
}
```

## Pre-building
You can pre-build all your assets with one command:

```dart
configureServer(Angel app) async {
  var vDir = new VirtualDirectory(transformers: [...]);
  await app.configure(vDir);
  
  // Build if in production
  if (app.isProduction) {
    await vDir.buildToDisk();
  }
}
```

## In Production
By default, transformers are disabled in production mode.
To force-enable them:

```dart
configureServer(Angel app) async {
  var vDir = new VirtualDirectory(useTransformersInProduction: true, transformers: [...]);
}
```