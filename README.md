# validate
[![version 0.0.1](https://img.shields.io/badge/pub-v0.0.1-red.svg)](https://pub.dartlang.org/packages/angel_validate)
[![build status](https://travis-ci.org/angel-dart/validate.svg)](https://travis-ci.org/angel-dart/validate)

(Not yet production ready, still missing several tests)

Validation library based on the `matcher` library, with Angel support.
Why re-invent the wheel, when you can use the same validators you already
use for tests?

This library runs both on the server, and on the client. Thus, you can use
the same validation rules for forms on the server, and on the frontend.

For convenience's sake, this library also exports `matcher`.

* [Examples](#examples)
  * [Creating a Validator](#creating-a-validator)
  * [Validating Data](#validating-data)
  * [Required Fields](#required-fields)
  * [Forbidden Fields](#forbidden-fields)
  * [Default Values](#default-values)
  * [Custom Validator Functions](#custom-validator-functions)
* [Auto-parsing Numbers](#autoparse)
* [Custom Error Messages](#custom-error-messages)
* [Extending Validators](#extending-validators)
* [Bundled Matchers](#bundled-matchers)
* [Nested Validators](#nested-validators)
* [Use with Angel](#use-with-angel)

# Examples

## Creating a Validator

```dart
import 'package:angel_validate/angel_validate.dart';

main() {
    var validator = new Validator({
        'username': isAlphaNum,
        'balance': [
            greaterThanOrEqualTo(0),
            lessThan(1000000)
        ]
    });
}
```

## Validating data

The `Validator` will filter out fields that have no validation rules.
You can rest easy knowing that attackers cannot slip extra data into
your applications.

```dart
main() {
    var result = validator.check(formData);

    if (!result.errors.isNotEmpty) {
        // Invalid data
    } else {
        // Safely handle filtered data
        return someSecureOperation(result.data);
    }
}
```

You can `enforce` validation rules, and throw an error if validation fails.

```dart
main() {
    try {
        // `enforce` will return the filtered data.
        var safeData = validator.enforce(formData);
    } on ValidationException catch(e) {
        print(e.errors);
    }
}
```

## Required Fields
Fields are optional by default.

Suffix a field name with a `'*'` to mark it as required, and
to throw an error if it is not present.

```dart
main() {
    var validator = new Validator({
        'googleId*': isString
    });
}
```

## Forbidden Fields
To prevent a field from showing up in valid data, suffix it
with a `'!'`.


## Default values

If not present, default values will be filled in *before* validation.
This means that they can still be used with required fields.

```dart
final Validator todo = new Validator({
    'text*': isString,
    'completed*': isBool
}, defaultValues: {
    'completed': false
});
```

Default values can also be parameterless, *synchronous* functions
that return a single value.

## Custom Validator Functions
Creating a whole `Matcher` class is sometimes cumbersome, but if
you pass a function to the constructor, it will be wrapped in a
`Matcher` instance.

(It simply returns the value of calling
[`predicate`](https://www.dartdocs.org/documentation/matcher/0.12.0%2B2/matcher/predicate.html).)

The function must *synchronously* return a `bool`.

```dart
main() {
    var validator = new Validator({
        'key*': (key) {
            var file = new File('whitelist.txt');
            return file.readFileSync().contains(key);
        }
    });
}
```

# Custom Error Messages
If these are not present, `angel_validate` will *attempt* to generate
a coherent error message on its own.

```dart
new Validator({
    'age': [greaterThanOrEqualTo(18)]
}, customErrorMessages: {
    'age': 'You must be an adult to see this page.'
});
```
The string `{{value}}` will be replaced inside your error message automatically.

# autoParse
Oftentimes, fields that we want to validate as numbers are passed as strings.
Calling `autoParse` will correct this before validation.

```dart
main() {
    var parsed = autoParse({
        'age': '34',
        'weight': '135.6'
    }, ['age', 'weight']);

    validator.enforce(parsed);
}
```

You can also call `checkParsed` or `enforceParsed` as a shorthand.

# Extending Validators
You can add situation-specific rules within a child validator.
You can also use `extend` to mark fields as required or forbidden that originally
were not. Default value and custom error message extension is also supported.

```dart
final Validator userValidator = new Validator({
    'username': isString,
    'age': [
        isNum,
        greaterThanOrEqualTo(18)
    ]
});
```

To mark a field as now optional, and no longer required,
suffix its name with a `'?'`.

```dart
var ageIsOptional = userValidator.extend({
    'age?': [
        isNum,
        greaterThanOrEqualTo(13)
    ]
});
```

Note that by default, new validation rules are simply appended to
the existing list. To completely overwrite existing rules, set the
`overwrite` flag to `true`.

```dart
register(Map userData) {
    var teenUser = userValidator.extend({
        'age': lessThan(18)
    }, overwrite: true);    
}
```

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

The remaining functionality is
[effectively implemented by the `matcher` package](https://www.dartdocs.org/documentation/matcher/0.12.0%2B2/matcher/matcher-library.html).

# Nested Validators
Very often, the data we validate contains other data within. You can pass
a `Validator` instance to the constructor, because it extends the
`Matcher` class.

```dart
main() {
    var bio = new Validator({
        'age*': [isInteger, greaterThanOrEqualTo(0)],
        'birthYear*': isInteger,
        'countryOfOrigin': isString
    });

    var book = new Validator({
        'title*': isString,
        'year*': [
            isNum,
            (year) {
                return year <= new DateTime.now().year;
            }
        ]
    });

    var author = new Validator({
        'bio*': bio,
        'books*': [
            isList,
            everyElement(book)
        ]
    }, defaultValues: {
        'books': []
    });
}
```

# Use with Angel

`server.dart` exposes five helper middleware:
* `validate(validator)`: Validates and filters `req.body`, and throws an `AngelHttpException.BadRequest` if data is invalid.
* `validateEvent(validator)`: Sets `e.data` to the result of validation on a service event.
* `validateQuery(validator)`: Same as `validate`, but operates on `req.query`.
* `autoParseBody(fields)`: Auto-parses numbers in `req.body`.
* `autoParseQuery(fields)`: Same as `autoParseBody`, but operates on `req.query`.

```dart
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/server.dart';

final Validator echo = new Validator({
    'message*': (String message) => message.length >= 5
});

final Validator todo = new Validator({
    'text*': isString,
    'completed*': isBool
}, defaultValues: {
    'completed': false
});

main() async {
    var app = new Angel();

    app.chain(validate(echo)).post('/echo', (req, res) async {
        res.write('You said: "${req.body["message"]}"');
    });

    app.service('api/todos')
        ..beforeCreated.listen(validateEvent(todo))
        ..beforeUpdated.listen(validateEvent(todo));

    await app.startServer();
}
```