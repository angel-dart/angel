# angel_mongo

![version 1.0.0-dev](https://img.shields.io/badge/version-1.0.0--dev-red.svg)

MongoDB-enabled services for the Angel framework.

# Installation
Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  angel_mongo: ^1.0.0-dev
```

# Usage
This library exposes three main classes: `Model`, `MongoService` and `MongoTypedService<T>`.

## Model
`Model` is class with no real functionality; however, it represents a basic MongoDB document, and your services should host inherited classes.

```dart
@Hooked()
class User extends Model {
  String username;
  String password;
}
```

## MongoService
This class interacts with a `DbCollection` (from mongo_dart) and serializing data to and from Maps.

## MongoTypedService<T>
Does the same as above, but serializes to and from a target class using json_god and its support for reflection.

See the tests for more usage examples.
