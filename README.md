# security
[![version 0.0.0-alpha+1](https://img.shields.io/badge/pub-v0.0.0--alpha+1-red.svg)](https://pub.dartlang.org/packages/angel_security)
[![build status](https://travis-ci.org/angel-dart/security.svg)](https://travis-ci.org/angel-dart/security)

Angel middleware designed to enhance application security by patching common Web security
holes.

Currently unfinished, with incomplete code coverage - **USE AT YOUR OWN RISK!!!**

## Sanitizing HTML

```dart
app.before.add(sanitizeHtmlInput());

// Or:
app.chain(sanitizeHtmlInput()).get(...)
```

## CSRF Tokens

```dart
app.chain(verifyCsrfToken()).post('/form', ...);
app.responseFinalizers.add(setCsrfToken());
```

## Banning IP's

```dart
app.before.add(banIp('1.2.3.4'));

// Or a range:
app.before.add(banIp('1.2.3.*'));
app.before.add(banIp('1.2.*.4'));

// Or multiple filters:
app.before.add(banIp(['1.2.3.4', '192.*.*.*', new RegExp(r'1\.2.\3.\4')]));
```