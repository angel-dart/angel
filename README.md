# angel_static
Static server middleware for Angel.

# Installation
In `pubspec.yaml`:

    dependencies:
        angel_framework: ^0.0.0-dev
        angel_static: ^1.0.0-beta

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
    angel.registerMiddleware("static", serveStatic(new Directory("build/web")));
    angel.get("*", "static");

    await angel.startServer(InternetAddress.LOOPBACK_IP_V4, 8080);
}
```

