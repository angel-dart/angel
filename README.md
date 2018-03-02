# serialize
[![Pub](https://img.shields.io/pub/v/angel_serialize.svg)](https://pub.dartlang.org/packages/angel_serialize)
[![build status](https://travis-ci.org/angel-dart/serialize.svg)](https://travis-ci.org/angel-dart/serialize)

Source-generated serialization for Dart objects. This package uses `package:source_gen` to eliminate
the time you spend writing boilerplate serialization code for your models.
`package:angel_serialize` also powers `package:angel_orm`.

* [Usage](#usage)
  * [Models](#models)
    * [Field Aliases](#aliases)
    * [Excluding Keys](#excluding-keys)
  * [Nesting](#nesting)
  * [ID and Date Fields](#id-and-dates)

# Usage
In your `pubspec.yaml`, you need to install the following dependencies:
```yaml
dependencies:
  angel_serialize: ^2.0.0-alpha
dev_dependencies:
  angel_serialize_generator: ^2.0.0-alpha
  build_runner: ^0.7.0
```

You'll want to create a Dart script, usually named `tool/phases.dart` that invokes
 `JsonModelGenerator` and `SerializerGenerator`.

```dart
import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';

final List<BuildAction> actions = [
  new BuildAction(new PartBuilder([const JsonModelGenerator()]),
      '<package-name>',
      inputs: const ['test/models/*.dart']),
  new BuildAction(new PartBuilder([const SerializerGenerator()], generatedExtension: '.serializer.g.dart'),
      '<package-name>',
      inputs: const ['test/models/*.dart'])
];
```

And then, a `tool/build.dart` can build your serializers:
```dart
import 'package:build_runner/build_runner.dart';
import 'phases.dart';

main() => build(actions, deleteFilesByDefault: true);
```

If you want to watch for file changes and re-build when necessary, replace the `build` call
with a call to `watch`. They take the same parameters.

# Models
There are a few changes opposed to normal Model classes. You need to add a `@serializable` annotation to your model
class to have it serialized, and a serializable model class's name should also start
with a leading underscore. In addition, you may consider using an `abstract` class.

Rather you writing the public class, `angel_serialize` does it for you. This means that the main class can have
its constructors automatically generated, in addition into serialization functions.

For example, say we have a `Book` model. Create a class named `_Book`:

```dart
library angel_serialize.test.models.book;

import 'package:angel_framework/common.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'book.g.dart';

@serializable
abstract class _Book extends Model {
  String author, title, description;
  int pageCount;
}
```

The following files will be generated:
  * `book.g.dart`
  * `book.serializer.g.dart`

## Aliases
Whereas Dart fields conventionally are camelCased, most database columns
tend to be snake_cased. This is not a problem, because we can define an alias
for a field.

By default `angel_serialize` will transform keys into snake case. Use `Alias` to
provide a custom name, or pass `autoSnakeCaseNames`: `false` to the builder;

```dart
@serializable
abstract class _Spy extends Model {
  /// Will show up as 'agency_id' in serialized JSON.
  /// 
  /// When deserializing JSON, instead of searching for an 'agencyId' key,
  /// it will use 'agency_id'.
  /// 
  /// Hooray!
  String agencyId;
  
  @Alias('foo')
  String someOtherField;
}
```

You can also override `autoSnakeCaseNames` per model:

```dart
@Serializable(autoSnakeCaseNames: false)
abstract class _OtherCasing extends Model {
  String camelCasedField;
}
```

## Excluding Keys
In pratice, there may keys that you want to exclude from JSON.
To accomplish this, simply annotate them with `@exclude`:

```dart
@serializable
abstract class _Whisper extends Model {
  /// Will never be serialized to JSON
  @exclude
  String secret;
}
```

There are times, however, when you want to only exclude either serialization
or deserialization, but not both. For example, you might want to deserialize
passwords from a database without sending them to users as JSON.

In this case, use `canSerialize` or `canDeserialize`:

```dart
@serializable
abstract class _Whisper extends Model {
  /// Will never be serialized to JSON
  /// 
  /// ... But it can be deserialized
  @Exclude(canDeserialize: true)
  String secret;
}
```

# Nesting
`angel_serialize` also supports a few types of nesting of `@serializable` classes:
* As a class member, ex. `Book myField`
* As the type argument to a `List`, ex. `List<Book>`
* As the second type argument to a `Map`, ex. `Map<String, Book>`

In other words, the following are all legal, and will be serialized/deserialized.
You can use either the underscored name of a child class (ex. `_Book`), or the
generated class name (ex `Book`):

```dart
@serializable
abstract class _Author extends Model {
  List<Book> books;
  Book newestBook;
  Map<String, Book> booksByIsbn;
}
```

If your model (`Author`) depends on a model defined in another file (`Book`),
then you will need to generate `book.g.dart` before, `author.g.dart`,
**in a separate build action**. This way, the analyzer can resolve the `Book` type.

# ID and Dates
This package will automatically generate `id`, `createdAt`, and `updatedAt` fields for you,
in the style of an Angel `Model`. To disable this, set `autoIdAndDateFields` to `false` in the
builder constructor.


You can also override `autoSnakeCaseNames` per model:

```dart
@Serializable(autoIdAndDateFields: false)
abstract class _Skinny extends Model {}
```
