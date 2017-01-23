# shelf
[![version 1.0.0](https://img.shields.io/badge/pub-v1.0.0-brightgreen.svg)](https://pub.dartlang.org/packages/angel_shelf)
[![build status](https://travis-ci.org/angel-dart/shelf.svg)](https://travis-ci.org/angel-dart/shelf)

Shelf interop with Angel. Will be deprecated by v2.0.0.

By version 2 of Angel, I will migrate the server to run on top of `shelf`.
Until then, use the code in this repo to embed existing shelf apps into
your Angel applications.

This will make it easy to layer your API over a production application,
rather than having to port code.

```dart
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_shelf/angel_shelf.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'api/api.dart';

main() async {
  final app = new Angel();
  
  // Angel routes on top
  await app.configure(new ApiController());
  
  // Re-route all other traffic to an
  // existing application.
  app.after.add(embedShelf(
    new shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(_echoRequest)
  ));
  
  await app.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
}
```
