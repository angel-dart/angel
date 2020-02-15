# jael
[![Pub](https://img.shields.io/pub/v/angel_jael.svg)](https://pub.dartlang.org/packages/angel_jael)
[![build status](https://travis-ci.org/angel-dart/jael.svg)](https://travis-ci.org/angel-dart/jael)


[Angel](https://angel-dart.github.io)
support for
[Jael](https://github.com/angel-dart/jael).

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  angel_jael: ^1.0.0-alpha
```

# Usage
Just like `mustache` and other renderers, configuring Angel to use
Jael is as simple as calling `app.configure`:

```dart
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_jael/angel_jael.dart';
import 'package:file/file.dart';

AngelConfigurer myPlugin(FileSystem fileSystem) {
    return (Angel app) async {
        // Connect Jael to your server...
        await app.configure(
        jael(fileSystem.directory('views')),
      );
    };
}
```

`package:angel_jael` supports caching views, to improve server performance.
You might not want to enable this in development, so consider setting
the flag to `app.isProduction`:

```
jael(viewsDirectory, cacheViews: app.isProduction);
```

Keep in mind that this package uses `package:file`, rather than
`dart:io`.

The following is a basic example of a server setup that can render Jael
templates from a directory named `views`:

```dart
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_jael/angel_jael.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';

main() async {
  var app = new Angel();
  var fileSystem = const LocalFileSystem();

  await app.configure(
    jael(fileSystem.directory('views')),
  );

  // Render the contents of views/index.jael
  app.get('/', (res) => res.render('index', {'title': 'ESKETTIT'}));

  app.use(() => throw new AngelHttpException.notFound());

  app.logger = new Logger('angel')
    ..onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });

  var server = await app.startServer(null, 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}
```

To apply additional transforms to parsed documents, provide a
set of `patch` functions, like in `package:jael_preprocessor`.