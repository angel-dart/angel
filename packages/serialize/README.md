# serialize

[![Pub](https://img.shields.io/pub/v/angel_serialize.svg)](https://pub.dartlang.org/packages/angel_serialize)
[![build status](https://travis-ci.org/angel-dart/serialize.svg)](https://travis-ci.org/angel-dart/serialize)

Source-generated serialization for Dart objects. This package uses `package:source_gen` to eliminate
the time you spend writing boilerplate serialization code for your models.
`package:angel_serialize` also powers `package:angel_orm`.

- [Usage](#usage)
  - [Models](#models)
    - [Subclasses](#subclasses)
    - [Field Aliases](#aliases)
    - [Excluding Keys](#excluding-keys)
    - [Required Fields](#required-fields)
    - [Adding Annotations to Generated Classes](#adding-annotations-to-generated-classes)
    - [Custom Serializers](#custom-serializers)
  - [Serialization](#serializaition)
  - [Nesting](#nesting)
  - [ID and Date Fields](#id-and-dates)
  - [Binary Data](#binary-data)
  - [TypeScript Definition Generator](#typescript-definitions)
  - [Constructor Parameters](#constructor-parameters)

# Usage

In your `pubspec.yaml`, you need to install the following dependencies:

```yaml
dependencies:
  angel_model: ^1.0.0
  angel_serialize: ^2.0.0
dev_dependencies:
  angel_serialize_generator: ^2.0.0
  build_runner: ^1.0.0
```

With the recent updates to `package:build_runner`, you can build models automatically,
anywhere in your project structure,
by running `pub run build_runner build`.

To tweak this:
https://pub.dartlang.org/packages/build_config

If you want to watch for file changes and re-build when necessary, replace the `build` call
with a call to `watch`. They take the same parameters.

# Models

There are a few changes opposed to normal Model classes. You need to add a `@serializable` annotation to your model
class to have it serialized, and a serializable model class's name should also start
with a leading underscore.

In addition, you may consider using an `abstract` class to ensure immutability
of models.

Rather you writing the public class, `angel_serialize` does it for you. This means that the main class can have
its constructors automatically generated, in addition into serialization functions.

For example, say we have a `Book` model. Create a class named `_Book`:

```dart
library angel_serialize.test.models.book;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
part 'book.g.dart';

@serializable
abstract class _Book extends Model {
  String get author;

  @SerializableField(defaultValue: '[Untitled]')
  String get title;

  String get description;

  int get pageCount;

  BookType get type;
}

/// It even supports enums!
enum BookType {
  fiction,
  nonFiction
}
```

The following file will be generated:

- `book.g.dart`

Producing these classes:

- `Book`: Extends or implements `_Book`; may be `const`-enabled.
- `BookSerializer`: static functionality for serializing `Book` models.
- `BookFields`: The names of all fields from the `Book` model, statically-available.
- `BookEncoder`: Allows `BookSerializer` to extend `Codec<Book, Map>`.
- `BookDecoder`: Also allows `BookSerializer` to extend `Codec<Book, Map>`.

And the following other features:
- `bookSerializer`: A top-level, `const` instance of `BookSerializer`.
- `Book.toString`: Prints out all of a `Book` instance's fields.

# Serialization

You can use the generated files as follows:

```dart
myFunction() {
  var warAndPeace = new Book(
    author: 'Leo Tolstoy',
    title: 'War and Peace',
    description: 'You will cry after reading this.',
    pageCount: 1225
  );

  // Easily serialize models into Maps
  var map = BookSerializer.toMap(warAndPeace);

  // Also deserialize from Maps
  var book = BookSerializer.fromMap(map);
  print(book.title); // 'War and Peace'

  // For compatibility with `JSON.encode`, a `toJson` method
  // is included that forwards to `BookSerializer.toMap`:
  expect(book.toJson(), map);

  // Generated classes act as value types, and thus can be compared.
  expect(BookSerializer.fromMap(map), equals(warAndPeace));
}
```

As of `2.0.2`, the generated output also includes information
about the serialized names of keys on your model class.

```dart
  myOtherFunction() {
    // Relying on the serialized key of a field? No worries.
      map[BookFields.author] = 'Zora Neale Hurston';
  }
}
```

## Customizing Serialization

Currently, these serialization methods are supported:

- to `Map`
- to JSON
- to TypeScript definitions

You can customize these by means of `serializers`:

```dart
@Serializable(serializers: const [Serializers.map, Serializers.json])
class _MyClass extends Model {}
```

## Subclasses
`angel_serialize` pulls in fields from parent classes, as well as
implemented interfaces, so it is extremely easy to share attributes among
model classes:

```dart
import 'package:angel_serialize/angel_serialize.dart';
part 'subclass.g.dart';

@serializable
class _Animal {
  @notNull
  String genus;
  @notNull
  String species;
}

@serializable
class _Bird extends _Animal {
  @DefaultsTo(false)
  bool isSparrow;
}

var saxaulSparrow = Bird(
  genus: 'Passer',
  species: 'ammodendri',
  isSparrow: true,
);
```

## Aliases

Whereas Dart fields conventionally are camelCased, most database columns
tend to be snake_cased. This is not a problem, because we can define an alias
for a field.

By default `angel_serialize` will transform keys into snake case. Use `alias` to
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

  @SerializableField(alias: 'foo')
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
  @SerializableField(exclude: true)
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
  @SerializableField(exclude: true, canDeserialize: true)
  String secret;
}
```

## Required Fields

It is easy to mark a field as required:

```dart
@serializable
abstract class _Foo extends Model {
  @SerializableField(isNullable: false)
  int myRequiredInt;

  @SerializableField(isNullable: false, errorMessage: 'Custom message')
  int myOtherRequiredInt;
}
```

The given field will be marked as `@required` in the
generated constructor, and serializers will check for its
presence, throwing a `FormatException` if it is missing.

## Adding Annotations to Generated Classes
There are times when you need the generated class to have annotations affixed to it:

```dart
@Serializable(
  includeAnnotations: [
    Deprecated('blah blah blah'),
    pragma('something...'),
  ]
)
abstract class _Foo extends Model {}
```

## Custom Serializers
`package:angel_serialize` does not cover every known Dart data type; you can add support for your own.
Provide `serializer` and `deserializer` arguments to `@SerializableField()` as you see fit.

They are typically used together. Note that the argument to `deserializer` will always be
`dynamic`, while `serializer` can receive the data type in question.

In such a case, you might want to also provide a `serializesTo` argument.
This lets the generator, as well as the ORM, apply the correct (de)serialization rules
and validations.

```dart
DateTime _dateFromString(s) => s is String ? HttpDate.parse(s) : null;
String _dateToString(DateTime v) => v == null ? null : HttpDate.format(v);

@serializable
abstract class _HttpRequest {
  @SerializableField(
    serializer: #_dateToString,
    deserializer: #_dateFromString,
    serializesTo: String)
  DateTime date;
}
```

# Nesting

`angel_serialize` also supports a few types of nesting of `@serializable` classes:

- As a class member, ex. `Book myField`
- As the type argument to a `List`, ex. `List<Book>`
- As the second type argument to a `Map`, ex. `Map<String, Book>`

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
in the style of an Angel `Model`. This will automatically be generated, **only** for classes
extending `Model`.

# Binary Data

`package:angel_serialize` also handles `Uint8List` fields, by means of serialization to
and from `base64` encoding.

# TypeScript Definitions

It is quite common to build frontends with JavaScript and/or TypeScript,
so why not generate typings as well?

To accomplish this, add `Serializers.typescript` to your `@Serializable()` declaration:

```dart
@Serializable(serializers: const [Serializers.map, Serializers.json, Serializers.typescript])
class _Foo extends Model {}
```

The aforementioned `_Author` class will generate the following in `author.d.ts`:

```typescript
interface Author {
  id: string;
  name: string;
  age: number;
  books: Book[];
  newest_book: Book;
  created_at: any;
  updated_at: any;
}
interface Library {
  id: string;
  collection: BookCollection;
  created_at: any;
  updated_at: any;
}
interface BookCollection {
  [key: string]: Book;
}
```

Fields with an `@Exclude()` that specifies `canSerialize: false` will not be present in the
TypeScript definition. The rationale for this is that if a field (i.e. `password`) will
never be sent to the client, the client shouldn't even know the field exists.

# Constructor Parameters

Sometimes, you may need to have custom constructor parameters, for example, when
using depedency injection frameworks. For these cases, `angel_serialize` can forward
custom constructor parameters.

The following:

```dart
@serializable
abstract class _Bookmark extends _BookmarkBase {
  @SerializableField(exclude: true)
  final Book book;

  int get page;
  String get comment;

  _Bookmark(this.book);
}
```

Generates:

```dart
class Bookmark extends _Bookmark {
  Bookmark(Book book,
      {this.id,
      this.page,
      this.comment,
      this.createdAt,
      this.updatedAt})
      : super(book);

  @override
  final String id;

  // ...
}
```
