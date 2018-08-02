# graphql_schema
[![Pub](https://img.shields.io/pub/v/graphql_schema.svg)](https://pub.dartlang.org/packages/graphql_schema)

An implementation of GraphQL's type system in Dart. Supports any platform where Dart runs.

# Usage
It's easy to define a schema with the
[helper functions](#helpers):

```dart
final GraphQLSchema todoSchema = new GraphQLSchema(
    query: objectType('Todo', [
  field('text', type: graphQLString.nonNullable()),
  field('created_at', type: graphQLDate)
]));
```

All GraphQL types are generic, in order to leverage Dart's strong typing support.

# Serialization
GraphQL types can `serialize` and `deserialize` input data.
The exact implementation of this depends on the type.

```dart
var iso8601String = graphQLDate.serialize(new DateTime.now());
var date = graphQLDate.deserialize(iso8601String);
print(date.millisecondsSinceEpoch);
```

# Validation
GraphQL types can `validate` input data.

```dart
var validation = myType.validate('@root', {...});

if (validation.successful) {
  doSomething(validation.value);
} else {
  print(validation.errors);
}
```

# Helpers
* `graphQLSchema` - Create a `GraphQLSchema`
* `objectType` - Create a `GraphQLObjectType` with fields
* `field` - Create a `GraphQLField` with a type/argument/resolver
* `listType` - Create a `GraphQLListType` with the provided `innerType`

# Types
All of the GraphQL scalar types are built in, as well as a `Date` type:
* `graphQLString`
* `graphQLId`
* `graphQLBoolean`
* `graphQLInt`
* `graphQLFloat`
* `graphQLDate`

## Non-Nullable Types
You can easily make a type non-nullable by calling its `nonNullable` method.

## List Types
Support for list types is also included. Use the `listType` helper for convenience.

```dart
/// A non-nullable list of non-nullable integers
listType(graphQLInt.nonNullable()).nonNullable();
```