# shelf
[![Pub](https://img.shields.io/pub/v/angel_shelf.svg)](https://pub.dartlang.org/packages/angel_shelf)
[![build status](https://travis-ci.org/angel-dart/shelf.svg)](https://travis-ci.org/angel-dart/shelf)

Shelf interop with Angel. This package lets you run `package:shelf` handlers via a custom adapter.

Use the code in this repo to embed existing shelf apps into
your Angel applications. This way, you can migrate legacy applications without
having to rewrite your business logic.

This will make it easy to layer your API over a production application,
rather than having to port code.

- [Usage](#usage)
  - [embedShelf](#embedshelf)
    - [Communicating with Angel](#communicating-with-angel-with-embedshelf)

# Usage

## embedShelf

This is a compliant `shelf` adapter that acts as an Angel request handler. You can use it as a middleware,
or attach it to individual routes.

```dart
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_shelf/angel_shelf.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'api/api.dart';

main() async {
  var app = new Angel();
  var http = new AngelHttp(app);

  // Angel routes on top
  await app.mountController<ApiController>();

  // Re-route all other traffic to an
  // existing application.
  app.fallback(embedShelf(
    new shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(_echoRequest)
  ));

  // Or, only on a specific route:
  app.get('/shelf', wrappedShelfHandler);

  await http.startServer(InternetAddress.loopbackIPV4, 3000);
  print(http.uri);
}
```

### Communicating with Angel with embedShelf

You can communicate with Angel:

```dart
handleRequest(shelf.Request request) {
  // Access original Angel request...
  var req = request.context['angel_shelf.request'] as RequestContext;

  // ... And then interact with it.
  req.container.registerNamedSingleton<Foo>('from_shelf', new Foo());

  // `req.container` is also available.
  var container = request.context['angel_shelf.container'] as Container;
  container.make<Truck>().drive();
}
```
