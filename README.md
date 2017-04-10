[![The Angel Framework](https://angel-dart.github.io/images/logo.png)](https://angel-dart.github.io)

[![Gitter](https://img.shields.io/gitter/room/nwjs/nw.js.svg)](https://gitter.im/angel_dart/discussion)
[![version: v1.0.0](https://img.shields.io/badge/pub-v1.0.0-brightgreen.svg)](https://pub.dartlang.org/packages/angel_common)

[Wiki (in-depth documentation)](https://github.com/angel-dart/angel/wiki)

[API Documentation](http://www.dartdocs.org/documentation/angel_common/latest)

[Roadmap](https://github.com/angel-dart/roadmap/blob/master/ROADMAP.md)

[File an Issue](https://github.com/angel-dart/roadmap/issues)

**The Dart server framework that's ready for showtime.**

Angel is a full-featured server-side Web application framework for the Dart programming language. It strives to be a flexible, extensible system, to be easily scalable, and to allow as much code to be shared between clients and servers as possible. Ultimately, I believe that this approach will shorten the time it takes to build a full-stack Web application, from start to finish. [Read more...](https://medium.com/the-angel-framework/announcing-angel-v1-0-0-beta-46dfb4aa8afe)

Like what you see? Please lend us a star. :star:

## Installation & Setup
*Having errors with a fresh Angel installation? See [here](https://github.com/angel-dart/angel/wiki/Installation-&-Setup) for help.*

Once you have [Dart](https://www.dartlang.org/) installed, bootstrapping a project is as simple as running one shell command:

Install the [Angel CLI](https://github.com/angel-dart/cli):

```bash
pub global activate angel_cli
```

Bootstrap a project:

```bash
angel init hello
```

You can even have your server run and be *live-reloaded* on file changes:

```dart
angel start
```

Next, check out the [detailed documentation](https://github.com/angel-dart/angel/wiki) to learn to flesh out your project.

## Features
With features like the following, Angel is the all-in-one framework you should choose to build your next project:
* [Advanced, Modular Routing](https://github.com/angel-dart/route)
* [Middleware](https://github.com/angel-dart/angel/wiki/Middleware)
* [Dependency Injection](https://github.com/angel-dart/angel/wiki/Dependency-Injection)
* And [much more](https://github.com/angel-dart)...

## Basic Example
More examples and complete projects can be found in the [angel-example](https://github.com/angel-example) organization.

The following is an [explosive application](https://github.com/angel-example/explode) complete with a REST API and
WebSocket support. It interacts with a MongoDB database, and reads configuration automatically from a `config/<ANGEL-ENV-NAME>.yaml` file. Templates are rendered with Mustache, and all responses are compressed via GZIP.

**All in just about 20 lines of actual code.**

```dart
import 'dart:async';
import 'package:angel_common/angel_common.dart';
import 'package:angel_websocket/server.dart';
import 'package:mongo_dart/mongo_dart.dart';

main() async {
  var app = await createServer();
  var server = await app.startServer(InternetAddress.LOOPBACK_IP_V4, 8080);
  print('Angel listening at http://${server.address.address}:${server.port}');
}

Future<Angel> createServer() async {
  // New instance...
  var app = new Angel();
  
  // Configuration
  await app.configure(loadConfigurationFile());
  await app.configure(mustache());
  Db db = new Db();
  await db.open(app.mongodb_url);
  app.container.singleton(db); // Add to DI

  // Routes
  app.get('/foo', (req, res) => res.render('hello'));
  
  app.post('/query', (Db db) async {
    // Db is an injected dependency here :)
    return await db.collection('foo').find().toList();
  });
  
  // Services (which build REST API's and are broadcasted over WS)
  app.use('/bombs', new MongoService(db.collection('bombs')));
  app.use('/users', new MongoService(db.collection('users')));
  app.use('/explosions', new AnonymousService(create: (data, [params]) => data));
  
  
  // Setup WebSockets, add GZIP, etc.
  await app.configure(new AngelWebSocket());
  app.responseFinalizers.add(gzip());
  
  return app;
}
```

## Join the team
Do you want to collaborate? Join the project at https://projectgroupie.com/projects/212 
