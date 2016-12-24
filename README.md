# angel_websocket
[![1.0.0-dev+6](https://img.shields.io/badge/version-1.0.0--dev+6-red.svg)](https://pub.dartlang.org/packages/angel_websocket)
[![build status](https://travis-ci.org/angel-dart/websocket.svg)](https://travis-ci.org/angel-dart/websocket)

WebSocket plugin for Angel.

This plugin broadcasts events from hooked services via WebSockets. 

In addition, it adds itself to the app's IoC container as `AngelWebSocket`, so that it can be used
in controllers as well.

WebSocket contexts are add to `req.properties` as `'socket'`.


# Usage

**Server-side**

```dart
import "package:angel_framework/angel_framework.dart";
import "package:angel_websocket/server.dart";

main() async {
  var app = new Angel();
  await app.configure(new AngelWebSocket("/ws"));
}

```

**Adding Handlers within a Controller**

`WebSocketController` extends a normal `Controller`, but also listens to WebSockets.

```dart
import 'dart:async';
import "package:angel_framework/angel_framework.dart";
import "package:angel_websocket/server.dart";

@Expose("/")
class MyController extends WebSocketController {
  @override
  void onConnect(WebSocketContext socket) {
    // On connect...
  }
  
  // Dependency injection works, too..
  @ExposeWs("read_message")
  void sendMessage(WebSocketContext socket, Db db) async {
    socket.send("found_message", db.collection("messages").findOne(where.id("...")));
  }
}
```

**In the Browser**

```dart
import "package:angel_websocket/browser.dart";

main() async {
  Angel app = new WebSockets("/ws");
  await app.connect();

  var Cars = app.service("api/cars");

  Cars.onCreated.listen((e) => print("New car: ${e.data}"));

  // Happens asynchronously
  Cars.create({"brand": "Toyota"});

  // Listen for arbitrary events
  app.on['custom_event'].listen((event) {
    // For example, this might be sent by a
    // WebSocketController.
    print('Hi!');
  });
}
```

**CLI Client**

```dart
import "package:angel_framework/angel_framework" as srv;
import "package:angel_websocket/io.dart";

// You can include these in a shared file and access on both client and server
class Car extends srv.Model {
  int year;
  String brand, make;

  Car({this.year, this.brand, this.make});

  @override String toString() => "$year $brand $make";
}

main() async {
  Angel app = new WebSockets("/ws");

  // Wait for WebSocket connection...
  await app.connect();

  var Cars = app.service("api/cars", type: Car);

  Cars.onCreated.listen((e) {
      // Automatically deserialized into a car :)
      Car car = e.data;

      // I just bought a new 2016 Toyota Camry!
      print("I just bought a new $car!");
  });

  // Happens asynchronously
  Cars.create({"year": 2016, "brand": "Toyota", "make": "Camry"});
}
```
