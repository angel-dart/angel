# angel_websocket
WebSocket plugin for Angel.

This plugin broadcasts events from hooked services via WebSockets. 

In addition,
it adds itself to the app's IoC container as `AngelWebSocket`, so that it can be used
in controllers as well.

WebSocket contexts are add to `req.params` as `'socket'`.


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

```dart
import 'dart:async';
import "package:angel_framework/angel_framework.dart";
import "package:angel_websocket/server.dart";

@Expose("/")
class MyController extends Controller {
  @override
  Future call(AngelBase app) async {
    var ws = app.container.make(AngelWebSocket);
    ws.onConnection.listen((WebSocketContext socket) {
      socket.on["message"].listen((WebSocketEvent e) {
        socket.send("new_message", { "text": e.data["text"] });
      });
    });
  }
}
```

**In the Browser**

```dart
import "package:angel_websocket/browser.dart";

main() async {
  Angel app = new WebSocketClient("/ws");
  var Cars = app.service("api/cars");

  Cars.onCreated.listen((e) => print("New car: ${e.data}"));

  // Happens asynchronously
  Cars.create({"brand": "Toyota"});
}
```

**CLI Client**

```dart
import "package:angel_framework/angel_framework" as srv;
import "package:angel_websocket/browser.dart";

// You can include these in a shared file and access on both client and server
class Car extends srv.Model {
  int year;
  String brand, make;

  Car({this.year, this.brand, this.make});

  @override String toString() => "$year $brand $make";
}

main() async {
  Angel app = new WebSocketClient("/ws");
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
