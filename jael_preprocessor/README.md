# jael_preprocessor
[![Pub](https://img.shields.io/pub/v/jael_preprocessor.svg)](https://pub.dartlang.org/packages/jael_preprocessor)
[![build status](https://travis-ci.org/angel-dart/jael.svg)](https://travis-ci.org/angel-dart/jael)

A pre-processor for resolving blocks and includes within
[Jael](https://github.com/angel-dart/jael) templates.

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  jael_prepreprocessor: ^1.0.0-alpha
```

# Usage
It is unlikely that you will directly use this package, as it is
more of an implementation detail than a requirement. However, it
is responsible for handling `include` and `block` directives
(template inheritance), so you are a package maintainer and want
to support Jael, read on.

To keep things simple, just use the `resolve` function, which will
take care of inheritance for you.

```dart
import 'package:jael_preprocessor/jael_preprocessor.dart' as jael;

myFunction() async {
  var doc = await parseTemplateSomehow();
  var resolved = await jael.resolve(doc, dir, onError: (e) => doSomething());
}
```

You may occasionally need to manually patch in functionality that is not
available through the official Jael packages. To achieve this, simply
provide an `Iterable` of `Patcher` functions:

```dart
myOtherFunction(jael.Document doc) {
  return jael.resolve(doc, dir, onError: errorHandler, patch: [
    syntactic(),
    sugar(),
    etc(),
  ]);
}
```

**This package uses `package:file`, rather than `dart:io`.**