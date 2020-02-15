import 'dart:async';

import 'package:angel_container/angel_container.dart';
import 'package:angel_container/mirrors.dart';

Future<void> main() async {
  // Create a container instance.
  var container = Container(const MirrorsReflector());

  // Register a singleton.
  container.registerSingleton<Engine>(Engine(40));

  // You can also omit the type annotation, in which the object's runtime type will be used.
  // If you're injecting an abstract class, prefer the type annotation.
  //
  // container.registerSingleton(Engine(40));

  // Register a factory that creates a truck.
  container.registerFactory<Truck>((container) {
    return _TruckImpl(container.make<Engine>());
  });

  // Use `make` to create an instance.
  var truck = container.make<Truck>();

  // You can also resolve injections asynchronously.
  container.registerFactory<Future<int>>((_) async => 24);
  print(await container.makeAsync<int>());

  // Asynchronous resolution also works for plain objects.
  await container.makeAsync<Truck>().then((t) => t.drive());

  // Register a named singleton.
  container.registerNamedSingleton('the_truck', truck);

  // Should print: 'Vroom! I have 40 horsepower in my engine.'
  truck.drive();

  // Should print the same.
  container.findByName<Truck>('the_truck').drive();

  // We can make a child container with its own factory.
  var childContainer = container.createChild();

  childContainer.registerFactory<Truck>((container) {
    return _TruckImpl(Engine(5666));
  });

  // Make a truck with 5666 HP.
  childContainer.make<Truck>().drive();

  // However, calling `make<Engine>` will return the Engine singleton we created above.
  print(childContainer.make<Engine>().horsePower);
}

abstract class Truck {
  void drive();
}

class Engine {
  final int horsePower;

  Engine(this.horsePower);
}

class _TruckImpl implements Truck {
  final Engine engine;

  _TruckImpl(this.engine);

  @override
  void drive() {
    print('Vroom! I have ${engine.horsePower} horsepower in my engine.');
  }
}
