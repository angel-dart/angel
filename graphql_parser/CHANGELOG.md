# 1.2.0
* Combine `ValueContext` and `VariableContext` into a single `InputValueContext` supertype.
    * Add `T computeValue(Map<String, dynamic> variables);`
    * Resolve [#23](https://github.com/angel-dart/graphql/issues/23).
* Deprecate old `ValueOrVariable` class, and parser/AST methods related to it.

# 1.1.4
* Fix broken int variable parsing - https://github.com/angel-dart/graphql/pull/32

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
