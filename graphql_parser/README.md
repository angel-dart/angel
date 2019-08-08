# graphql_parser
[![Pub](https://img.shields.io/pub/v/graphql_parser.svg)](https://pub.dartlang.org/packages/graphql_parser)
[![build status](https://travis-ci.org/angel-dart/graphql.svg)](https://travis-ci.org/angel-dart/graphql)

Parses GraphQL queries and schemas.

*This library is merely a parser/visitor*. Any sort of actual GraphQL API functionality must be implemented by you,
or by a third-party package.

[Angel framework](https://angel-dart.github.io)
users should consider 
[`package:angel_graphql`](https://pub.dartlang.org/packages/angel_graphql)
as a dead-simple way to add GraphQL functionality to their servers.

# Installation
Add `graphql_parser` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  graphql_parser: ^1.0.0
```

# Usage
The AST featured in this library was originally directly based off this ANTLR4 grammar created by Joseph T. McBride:
https://github.com/antlr/grammars-v4/blob/master/graphql/GraphQL.g4

It has since been updated to reflect upon the grammar in the official GraphQL
specification (
[June 2018](https://facebook.github.io/graphql/June2018/)).

```dart
import 'package:graphql_parser/graphql_parser.dart';

doSomething(String text) {
  var tokens = scan(text);
  var parser = Parser(tokens);
  
  if (parser.errors.isNotEmpty) {
    // Handle errors...
  }
  
  // Parse the GraphQL document using recursive descent
  var doc = parser.parseDocument();
  
  // Do something with the parsed GraphQL document...
}
```
