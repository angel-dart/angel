# 2.0.9+4
* Remove `defaults` in `build.yaml`.

# 2.0.9+3
* Fix a cast error when self-referencing nested list expressions.

# 2.0.9+2
* Fix previously unseen cast errors with enums.

# 2.0.9+1
* Fix a cast error when deserializing nested model classes.

# 2.0.9
* Upgrade to `source_gen@^0.8.0`.

# 2.0.8+3
* Don't fail on `null` in `toMap`.
* Support self-referencing via `toJson()`.

# 2.0.8+2
* Better discern when custom methods disqualify classes
from `const` protection.
 
# 2.0.8+1
* Fix generation of `const` constructors with iterables.

# 2.0.8
* Now supports de/serialization of `enum` types.
* Generate `const` constructors when possible.
* Remove `whereType`, perform manual coercion.
* Generate a `fromMap` with typecasting, for Dart 2's sake.

# 2.0.7
* Create unmodifiable Lists and Maps.
* Support `@required` on fields.
* Affix an `@immutable` annotation to classes, if
`package:meta` is imported.
* Add `/// <reference path="..." />` to TypeScript models.

# 2.0.6
* Support for using `abstract` to create immutable model classes.
* Add support for custom constructor parameters.
* Closed [#21](https://github.com/angel-dart/serialize/issues/21) - better naming
of `Map` types.
* Added overridden `==` operators.

# 2.0.5
* Deserialization now supports un-serialized `DateTime`.
* Better support for regular typed Lists and Maps in TypeScript.

# 2.0.4
* Fields in TypeScript definitions are now nullable by default.

# 2.0.3
* Added a `TypeScriptDefinitionBuilder`.

# 2.0.2
* Generates an `XFields` class with the serialized names of
all fields in a model class `X`.
* Removed unnecessary named parameters from `XSerializer.fromMap`.

# 2.0.1
* Ensured that `List` is only transformed if
it generically references a `Model`.