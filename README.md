# orm
[![Pub](https://img.shields.io/pub/v/angel_orm.svg)](https://pub.dartlang.org/packages/angel_orm)
[![build status](https://travis-ci.org/angel-dart/orm.svg)](https://travis-ci.org/angel-dart/orm)

**This project is currently in the early stages, and may change at any given
time without warning.**

Source-generated ORM for use with the Angel framework. Documentation is coming soon.
This ORM can work with virtually any database, thanks to the functionality exposed by
`package:query_builder`.

Your model, courtesy of `package:angel_serialize`:

```dart
library angel_orm.test.models.car;

import 'package:angel_framework/common.dart';
import 'package:angel_orm/angel_orm.dart' as orm;
import 'package:angel_serialize/angel_serialize.dart';
part 'car.g.dart';

@serializable
@orm.model
class _Car extends Model {
  String manufacturer;
  int year;
}
```

After building, you'll have access to a `Repository` class with strongly-typed methods that
allow to run asynchronous queries without a headache.
You can run complex queries like:

```dart
import 'package:angel_framework/angel_framework.dart';
import 'package:postgres/postgres.dart';
import 'car.dart';
import 'car.orm.g.dart';

/// Returns an Angel plug-in that connects to a PostgreSQL database, and sets up a controller connected to it...
AngelConfigurer connectToCarsTable(PostgreSQLConnection connection) {
  return (Angel app) async {
    // Instantiate a Car repository, which is auto-generated. This class helps us build fluent queries easily.
    var cars = new CarRepository(connection);
    
    // Register it with Angel's dependency injection system.
    // 
    // This means that we can use it as a parameter in routes and controllers.
    app.container.singleton(cars);
    
    // Attach the controller we create below
    await app.configure(new CarService(cars));
  };
}

@Expose('/cars')
class CarService extends Controller {
  /// `manufacturerId` and `CarRepository` in this case would be dependency-injected. :)
  @Expose('/:manufacturerId/years')
  getAllYearsForManufacturer(String manufacturerId, CarRepository cars) {
    return
      cars
        .whereManufacturer(manufacturerId)
        .get()
        .map((Car car) {
          // Cars are deserialized automatically, woohoo!
          return car.year;
        })
        .toList();
  }
}
```