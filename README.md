# serialize
[![Pub](https://img.shields.io/pub/v/angel_serialize.svg)](https://pub.dartlang.org/packages/angel_serialize)
[![build status](https://travis-ci.org/angel-dart/serialize.svg)](https://travis-ci.org/angel-dart/serialize)

Source-generated serialization for Dart objects. This package uses `package:source_gen` to eliminate
the time you spend writing boilerplate serialization code for your models.
`package:angel_serialize` also powers `package:angel_orm`.

* [Usage](#usage)
  * [Models](#models)
    * [`@Alias(...)`](#aliases)
    * [`@exclude`](#excluding-keys)
  * [Nesting](#nesting)

# Usage
In your `pubspec.yaml`, you need to install the following dependencies:
```yaml
dependencies:
  angel_serialize: ^1.0.0-alpha
dev_dependencies:
  angel_serialize_builder: ^1.0.0-alpha
  build_runner: ^0.3.0
```

You'll want to create a Dart script, usually named `tool/phases.dart` that invokes
the `JsonModelGenerator`.

```dart
import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_serialize_builder/angel_serialize_builder.dart';

final PhaseGroup PHASES = new PhaseGroup.singleAction(
    new GeneratorBuilder([const JsonModelGenerator()]),
    new InputSet('[YOUR_PACKAGE_NAME_HERE]', const ['lib/src/models/*.dart']));
```

And then, a `tool/build.dart` can build your serializers:
```dart
import 'package:build_runner/build_runner.dart';
import 'phases.dart';

main() => build(PHASES, deleteFilesByDefault: true);
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

The following will be generated in `book.g.dart`:
```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.book;

// **************************************************************************
// Generator: JsonModelGenerator
// Target: abstract class _Book
// **************************************************************************

class Book extends _Book {
  @override
  String id;

  @override
  String author;

  @override
  String title;

  @override
  String description;

  @override
  int pageCount;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Book(
      {this.id,
      this.author,
      this.title,
      this.description,
      this.pageCount,
      this.createdAt,
      this.updatedAt});

  factory Book.fromJson(Map data) {
    return new Book(
        id: data['id'],
        author: data['author'],
        title: data['title'],
        description: data['description'],
        pageCount: data['page_count'],
        createdAt: data['created_at'] is DateTime
            ? data['created_at']
            : (data['created_at'] is String
                ? DateTime.parse(data['created_at'])
                : null),
        updatedAt: data['updated_at'] is DateTime
            ? data['updated_at']
            : (data['updated_at'] is String
                ? DateTime.parse(data['updated_at'])
                : null));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'title': title,
        'description': description,
        'page_count': pageCount,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Book parse(Map map) => new Book.fromJson(map);
  
  Book clone() {
    return new Book.fromJson(toJson());
  }
}
```

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

# Nesting
`angel_serialize` also supports a few types of nesting of `@serializable` classes:
* As a class member
* As the type argument to a `List`
* As the second type argument to a `Map`

In other words, the following are all legal, and will be serialized/deserialized.
Be sure to use the underscored name of a child class (ex. `_Book`):

```dart
@serializable
abstract class _Author extends Model {
  List<_Book> books;
  _Book newestBook;
  Map<String, _Book> booksByIsbn;
}
```

The caveat here is that nested classes must be written in the same file. `source_gen`
otherwise will not be able to resolve the nested type.

# ID and Dates
This package will automatically generate `id`, `createdAt`, and `updatedAt` fields for you,
in the style of an Angel `Model`. To disable this, set `autoIdAndDates` to `false` in the
builder constructor.