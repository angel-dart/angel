# graphql_parser
[![Pub](https://img.shields.io/pub/v/graphql_parser.svg)](https://pub.dartlang.org/packages/graphql_parser)
[![build status](https://travis-ci.org/thosakwe/graphql_parser.svg)](https://travis-ci.org/thosakwe/graphql_parser)

Parses GraphQL queries and schemas. Also includes a `GraphQLVisitor` class.

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
The AST featured in this library is directly based off this ANTLR4 grammar created by Joseph T. McBride:
https://github.com/antlr/grammars-v4/blob/master/graphql/GraphQL.g4

```dart
import 'package:graphql_parser/graphql_parser.dart';

doSomething(String text) {
  var tokens = scan(text);
  var parser = new Parser(tokens);
  
  // Parse the GraphQL document using recursive descent
  var doc = parser.parseDocument();
  
  // Do something with the parsed GraphQL document...
}
```
