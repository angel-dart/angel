# validate
[![Pub](https://img.shields.io/pub/v/angel_validate.svg)](https://pub.dartlang.org/packages/angel_validate)
[![build status](https://travis-ci.org/angel-dart/validate.svg)](https://travis-ci.org/angel-dart/validate)

Strongly-typed form handlers and validators for Angel.
Version `3.x` is a major improvement over `2.x`, though it does include breaking changes.

`package:angel_validate` allows you to easily sanitize incoming data, and to deserialize
that data into Dart classes (usually using `package:angel_serialize`).

# Field
The basic unit is the `Field` class, which is a type-safe way to read
values from a `RequestContext`. Here is a simple example of using a
`TextField` instance to read a value from the URL query parameters:

```dart
app.get('/hello', (req, res) async {
  var nameField = TextField('name');
  var name = await nameField.getValue(req, query: true); // String
  return 'Hello, $name!';
});
```

A `Field` can also use `Matcher` objects from `package:matcher` (which you may recognize from
its usage in `package:test`):

```dart
var positiveNumberField = IntField('pos_num').match([isPositive]);
```

There are several included field types:
* `TextField`
* `BoolField`
* `NumField`
* `DoubleField`
* `IntField`
* `DateTimeField`
* `FileField`
* `ImageField`

# Forms
The `Form` class lets you combine `Field` instances, and decode
request bodies into `Map<String, dynamic>`. Unrecognized fields are
stripped out of the body, so a `Form` is effectively a whitelist.

```dart
var todoForm = Form(fields: [
  TextField('text'),
  BoolField('is_complete'),
]);

// Validate a request body, and deserialize it immediately.
var todo = await todoForm.deserialize(req, TodoSerializer.fromMap);

// Same as above, but with a Codec<Todo, Map> (i.e. via `angel_serialize`).
var todo = await todoForm.decode(req, todoSerializer);

// Lower-level functionality, typically not called directly.
// Use it if you want to handle validation errors directly, without
// throwing exceptions.

@serializable
class _Todo {
  String text;
  bool isComplete;
}
```

## Form Rendering
TODO: Docs about this

# Bundled Matchers
This library includes some `Matcher`s for common validations,
including:

* `isAlphaDash`: Asserts that a `String` is alphanumeric, but also lets it contain dashes or underscores.
* `isAlphaNum`: Asserts that a `String` is alphanumeric.
* `isBool`: Asserts that a value either equals `true` or `false`.
* `isEmail`: Asserts that a `String` complies to the RFC 5322 e-mail standard.
* `isInt`: Asserts that a value is an `int`.
* `isNum`: Asserts that a value is a `num`.
* `isString`: Asserts that a value is a `String`.
* `isNonEmptyString`: Asserts that a value is a non-empty `String`.
* `isUrl`: Asserts that a `String` is an HTTPS or HTTP URL.

The remaining functionality is
[effectively implemented by the `matcher` package](https://www.dartdocs.org/documentation/matcher/latest/matcher/matcher-library.html).