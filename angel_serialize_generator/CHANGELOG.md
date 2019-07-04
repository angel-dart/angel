# 2.5.0
* Support mutable models (again).
* Use `whereType()` instead of chaining `where()` and `cast()`.
* Support pulling fields from parent classes and interfaces.
* Only generate `const` constructors if *all*
fields lack a setter.
* Don't type-annotate initializing formals.

# 2.4.4
* Remove unnecessary `new` and `const`.

# 2.4.3
* Generate `Codec` and `Converter` classes.
* Generate `toString` methods.
* Include original documentation comments from the model.

# 2.4.2
* Fix bug where enums didn't support default values.
* Stop emitting `@required` on items with default values.
* Create default `@SerializableField` for fields without them.

# 2.4.1+1
* Change `as Iterable<Map>` to `.cast<Map>`.

# 2.4.1
* Support `serializesTo`.
* Don't emit `@required` if there is a default value.
* Deprecate `autoIdAndDateFields`.

# 2.4.0
* Introduce `@SerializableField`, and say goodbye to annotation hell.
* Support custom (de)serializers.
* Allow passing of annotations to the generated class.
* Fixted TypeScript `ref` generator.

# 2.3.0
* Add `@DefaultValue` support.

# 2.2.2
* Split out TS def builder, to emit to source.

# 2.2.1
* Explicit changes for assisting `angel_orm_generator`.

# 2.2.0
* Build to `cache`.
* Only generate one `.g.dart` file.
* Support for `Uint8List`.
* Use `.cast()` for `List`s and `Map`s of *non-`Model`* types.

# 2.1.2
* Add `declare module` to generated TypeScript files.

# 2.1.1
* Generate `hashCode`.

# 2.1.0
* Removed dependency on `package:id`.
* Update dependencies for Dart2Stable.
* `jsonModelBuilder` now uses `SharedPartBuilder`, rather than
`PartBuilder`.

# 2.0.10
* Generate `XFields.allFields` constant.
* No longer breaks in cases where `dynamic` is present.
* Call `toJson` in `toMap` on nested models.
* Never generate named parameters from private fields.
* Use the new `@generatedSerializable` to *always* find generated
models.

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