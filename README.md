# angel_websocket
WebSocket plugin for Angel. Features JWT support.


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
