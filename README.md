# shelf
[![Pub](https://img.shields.io/pub/v/angel_shelf.svg)](https://pub.dartlang.org/packages/angel_shelf)
[![build status](https://travis-ci.org/angel-dart/shelf.svg)](https://travis-ci.org/angel-dart/shelf)

Shelf interop with Angel. This package lets you run `package:shelf` handlers via a custom adapter.
It also includes a plug-in that configures Angel to *natively* run `shelf` response handlers.

Use the code in this repo to embed existing shelf apps into
your Angel applications. This way, you can migrate legacy applications without
having to rewrite your business logic.

This will make it easy to layer your API over a production application,
rather than having to port code.

* [Usage](#usage)
  * [embedShelf](#embedshelf)
    * [Communicating with Angel](#communicating-with-angel-with-embedshelf)
  * [supportShelf](#supportshelf)
    * [Communicating with Angel](#communicating-with-angel-with-supportshelf)

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
  
  // Only on a specific route
  app.get('/shelf', handler);
  
  await app.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
}
```

### Communicating with Angel with embedShelf
You can communicate with Angel:

```dart
handleRequest(shelf.Request request) {
  // Access original Angel request...
  var req = request.context['angel_shelf.request'] as RequestContext;
  
  // ... And then interact with it.
  req.inject('from_shelf', new Foo());
  
  // `req.properties` are also available.
  var props = request.context['angel_shelf.properties'] as Map;
  
}
```

## supportShelf
This plug-in takes advantage of Angel's middleware system and dependency injection to patch a server
to run `shelf` request handlers as though they were Angel request handlers. Hooray for integration!

You'll want to run this before adding any other response finalizers that depend on
the response content being effectively final, i.e. GZIP compression.

**NOTE**: Do not inject a `shelf.Request` into your request under the name `req`. If you do,
Angel will automatically inject a `RequestContext` instead.

```dart
configureServer(Angel app) async {
  // Return a shelf Response
  app.get('/shelf', (shelf.Request request) => new shelf.Response.ok('Yay!'));
  
  // Return an arbitrary value.
  //
  // This will be serialized by Angel as per usual.
  app.get('/json', (shelf.Request request) => {'foo': 'bar'});
  
  // You can still throw Angel exceptions.
  //
  // Don't be fooled: just because this is a shelf handler, doesn't mean
  // it's not an Angel response handler too. ;)
  app.get('/error', (shelf.Request request) {
    throw new AngelHttpException.forbidden();
  });
  
  // Make it all happen!
  await app.configure(supportShelf());
}
```

### Communicating with Angel with supportShelf
The following keys will be present in the shelf request's context:
  * `angel_shelf.request` - Original RequestContext
  * `angel_shelf.response` - Original ResponseContext
  * `angel_shelf.properties` - Original RequestContext's properties
  
If the original `RequestContext` contains a Map named `shelf_context` in its `properties`,
then it will be merged into the shelf request's context.

If the handler returns a `shelf.Response`, then it will be present in `ResponseContext.properties`
as `shelf_response`.