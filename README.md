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

Db db = new Db('mongodb://localhost:27017/local');
await db.open();

app.use('/api/users', new MongoTypedService<User>(db.collection("users")));

app.service('api/users').afterCreated.listen((HookedServiceEvent event) {
	print("New user: ${event.result}");
});
```

## MongoService
This class interacts with a `DbCollection` (from mongo_dart) and serializing data to and from Maps.

## MongoTypedService<T>
Does the same as above, but serializes to and from a target class using json_god and its support for reflection.

## Querying
You can query these services as follows:

    /path/to/service?foo=bar

The above will query the database to find records where 'foo' equals 'bar'. Thanks to body_parser, this
also works with numbers, and even Maps.

	/path/to/service?$sort=createdAt
	/path/to/service?$sort.createdAt=1

The former will sort result in ascending order of creation, and so will the latter. 

    List queried = await MyService.index({r"$query": where.id(new ObjectId.fromHexString("some hex string"})));

And, of course, you can use mongo_dart queries. Just pass it as `query` within `params`.

See the tests for more usage examples.
