# rethink
[![version 1.0.7](https://img.shields.io/badge/pub-1.0.7-brightgreen.svg)](https://pub.dartlang.org/packages/angel_rethink)
[![build status](https://travis-ci.org/angel-dart/rethink.svg?branch=master)](https://travis-ci.org/angel-dart/rethink)

RethinkDB-enabled services for the Angel framework.

# Installation
Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  angel_rethink: ^1.0.0
```

`package:rethinkdb_driver2` will be installed as well.

# Usage
This library exposes one class: `RethinkService`. By default, these services will even
listen to [changefeeds](https://www.rethinkdb.com/docs/changefeeds/ruby/) from the database,
which makes them very suitable for WebSocket use.

However, only `CREATED`, `UPDATED` and `REMOVED` events will be fired. This is technically not
a problem, as it lowers the numbers of events you have to handle on the client side. ;)

## Model
`Model` is class with no real functionality; however, it represents a basic document, and your services should host inherited classes.
Other Angel service providers host `Model` as well, so you will easily be able to modify your application if you ever switch databases.

```dart
class User extends Model {
  String username;
  String password;
}

main() async {
    var r = new RethinkDb();
    var conn = await r.connect();

    app.use('/api/users', new RethinkService(conn, r.table('users')));
    
    // Add type de/serialization if you want
    app.use('/api/users', new TypedService<User>(new RethinkService(conn, r.table('users'))));

    // You don't have to even use a table...
    app.use('/api/pro_users', new RethinkService(conn, r.table('users').filter({'membership': 'pro'})));
    
    app.service('api/users').afterCreated.listen((event) {
        print("New user: ${event.result}");
    });
}
```

## RethinkService
This class interacts with a `Query` (usually a table) and serializes data to and from Maps.

## RethinkTypedService<T>
Does the same as above, but serializes to and from a target class using `package:json_god` and its support for reflection.

## Querying
You can query these services as follows:

    /path/to/service?foo=bar

The above will query the database to find records where 'foo' equals 'bar'.

The former will sort result in ascending order of creation, and so will the latter. 

You can use advanced queries:

```dart
// Pass an actual query...
service.index({'query': r.table('foo').filter(...)});

// Or, a function that creates a query from a table...
service.index({'query': (table) => table.getAll('foo')});

// Or, a Map, which will be transformed into a `filter` query:
service.index({'query': {'foo': 'bar', 'baz': 'quux'}});
```

You can also apply sorting by adding a `reql` parameter on the server-side.

```dart
service.index({'reql': (query) => query.sort(...)});
```

See the tests for more usage examples.
