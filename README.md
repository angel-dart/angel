# security
[![version 0.0.0](https://img.shields.io/badge/pub-v0.0.0--alpha-red.svg)](https://pub.dartlang.org/packages/angel_security)
[![build status](https://travis-ci.org/angel-dart/security.svg)](https://travis-ci.org/angel-dart/security)

Angel middleware designed to enhance application security.

Currently far from finished, with incomplete code coverage - **USE AT YOUR OWN RISK!!!**

## Sanitizing HTML

```dart
app.before.add(sanitizeHtmlInput());

// Or:
app.chain(sanitizeHtmlInput()).get(...)
```