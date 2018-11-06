# sembast
[![Pub](https://img.shields.io/pub/v/angel_sembast.svg)](https://pub.dartlang.org/packages/angel_sembast)
[![build status](https://travis-ci.org/angel-dart/sembast.svg)](https://travis-ci.org/angel-dart/sembast)

package:sembast-powered CRUD services for the Angel framework.

# Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  angel_sembast: ^1.0.0
```

# Usage

This library exposes one main class: `SembastService`.

## SembastService

This class interacts with a `Database` and `Store` (from `package:sembast`) and serializes data to and from Maps.

## Querying

You can query these services as follows:

    /path/to/service?foo=bar

The above will query the database to find records where 'foo' equals 'bar'.

The former will sort result in ascending order of creation, and so will the latter.

```dart
List queried = await MyService.index({r"query": where.id(new Finder(filter: new Filter(...))));
```

Of course, you can use `package:sembast` queries. Just pass it as `query` within `params`.

See the tests for more usage examples.
