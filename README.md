# angel_mongo

[![version 1.1.1](https://img.shields.io/badge/pub-1.1.1-brightgreen.svg)](https://pub.dartlang.org/packages/angel_mongo)
[![build status](https://travis-ci.org/angel-dart/mongo.svg?branch=master)](https://travis-ci.org/angel-dart/mongo)

MongoDB-enabled services for the Angel framework.

# Installation
Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  angel_mongo: ^1.0.0
```

# Usage
This library exposes two main classes: `MongoService` and `MongoTypedService<T>`.

## Model
`Model` is class with no real functionality; however, it represents a basic document, and your services should host inherited classes.
Other Angel service providers host `Model` as well, so you will easily be able to modify your application if you ever switch databases.

```dart
class User extends Model {
  String username;
  String password;
}

main() async {
    Db db = new Db('mongodb://localhost:27017/local');
    await db.open();
    
    app.use('/api/users', new MongoTypedService<User>(db.collection("users")));
    
    app.service('api/users').afterCreated.listen((event) {
        print("New user: ${event.result}");
    });
}
```

## MongoService
This class interacts with a `DbCollection` (from mongo_dart) and serializing data to and from Maps.

## MongoTypedService<T>
Does the same as above, but serializes to and from a target class using json_god and its support for reflection.

## Querying
You can query these services as follows:

    /path/to/service?foo=bar

The above will query the database to find records where 'foo' equals 'bar'.

The former will sort result in ascending order of creation, and so will the latter. 

    List queried = await MyService.index({r"$query": where.id(new ObjectId.fromHexString("some hex string"})));

And, of course, you can use mongo_dart queries. Just pass it as `query` within `params`.

See the tests for more usage examples.
