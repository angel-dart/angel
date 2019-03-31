# 1.1.3
* Add `Parser.nextName`, and remove all formerly-reserved words from the lexer.
Resolves [#19](https://github.com/angel-dart/graphql/issues/19).

# 1.1.2
* Parse the `subscription` keyword.

# 1.1.1
* Pubspec updates for Dart 2.

# 1.1.0
* Removed `GraphQLVisitor`.
* Enable parsing operations without an explicit
name.
* Parse `null`.
* Completely ignore commas.
* Ignore Unicode BOM, as per the spec.
* Parse object values.
* Parse enum values.