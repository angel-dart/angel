# graphql_generator
[![Pub](https://img.shields.io/pub/v/graphql_generator.svg)](https://pub.dartlang.org/packages/graphql_generator)
[![build status](https://travis-ci.org/angel-dart/graphql.svg)](https://travis-ci.org/angel-dart/graphql)

Generates `package:graphql_schema` schemas for
annotated class.

Replaces `convertDartType` from `package:graphql_server`.

## Usage
Usage is very simple. You just need a `@graphQLClass` or `@GraphQLClass()` annotation
on any class you want to generate an object type for.

Individual fields can have a `@GraphQLDocumentation()` annotation, to provide information
like descriptions, deprecation reasons, etc.

```dart
@graphQLClass
@GraphQLDocumentation(description: 'Todo object type')
class Todo {
  String text;

  /// Whether this item is complete
  bool isComplete;
}

void main() {
  print(todoGraphQLType.fields.map((f) => f.name));
}
```

The following is generated (as of April 18th, 2019):

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// _GraphQLGenerator
// **************************************************************************

/// Auto-generated from [Todo].
final GraphQLObjectType todoGraphQLType = objectType('Todo',
    isInterface: false,
    description: 'Todo object type',
    interfaces: [],
    fields: [
      field('text', graphQLString),
      field('isComplete', graphQLBoolean, description: 'Whether this item is complete')
    ]);
```
