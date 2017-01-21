# security
[![version 0.0.0-alpha+4](https://img.shields.io/badge/pub-v0.0.0--alpha+4-red.svg)](https://pub.dartlang.org/packages/angel_security)
[![build status](https://travis-ci.org/angel-dart/security.svg)](https://travis-ci.org/angel-dart/security)

Angel middleware designed to enhance application security by patching common Web security
holes.

Currently unfinished, with incomplete code coverage - **USE AT YOUR OWN RISK!!!**

* Generic Middleware
    * [Sanitizing HTML](#sanitizing-html)
    * [CSRF Tokens](#csrf-tokens)
    * [Banning by IP/Origin](#banning-by-ip)
    * [Trusted Proxy](#trusted-proxy)
    * [Throttling Requests](#throttling-requests)
* [Helmet Port](#helmet)
* [Service Hooks](#service-hooks)
* [Permissions](#permissions)

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

## Banning by IP

```dart
app.before.add(banIp('1.2.3.4'));

// Or a range:
app.before.add(banIp('1.2.3.*'));
app.before.add(banIp('1.2.*.4'));

// Or multiple filters:
app.before.add(banIp(['1.2.3.4', '192.*.*.*', new RegExp(r'1\.2.\3.\4')]));

// Also can ban origins
app.before.add(banOrigin('*.known-attacker.com'));

// By default, `banOrigin` forces users to have an `Origin` header.
// Use this flag to disable it:
app.before.add(banOrigin('evil.site', allowEmptyOrigin: true));
```

## Trusted Proxy
Works well with Apache or Nginx.

```dart
// ONLY trust localhost X-Forwarded-* headers
app.before.add(trustProxy('127.0.0.1'));
```

## Throttling Requests
Throws a `429` error if the given rate limit is exceeded.

```dart
// Example: 5 requests per minute
app.before.add(throttleRequests(5, new Duration(minutes: 1)));
```

# Helmet
`security` includes a port of [`helmetjs`](https://github.com/helmetjs/helmet).
Helmet includes 11 middleware that attempt to enhance security via HTTP headers.

Call `helmet` to include all of them.

```dart
import 'package:angel_security/helmet.dart';
```

# Service Hooks
Also included are a set of service hooks, [ported from FeathersJS](https://github.com/feathersjs/feathers-legacy-authentication-hooks).

```dart
import 'package:angel_security/hooks.dart';
```

# Permissions
See the tests. 