# security
[![version 0.0.7](https://img.shields.io/badge/pub-v0.0.7-red.svg)](https://pub.dartlang.org/packages/angel_security)
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
Also included are a set of service hooks, some [ported from FeathersJS](https://github.com/feathersjs/feathers-legacy-authentication-hooks).
Others are created just for Angel.

```dart
import 'package:angel_security/hooks.dart' as hooks;
```

Included:
* `addUserToParams`
* `associateCurrentUser`,
* `hashPassword`
* `queryWithCurrentUser`
* `restrictToAuthenticated`
* `restrictToOwner`
* `variantPermission`

Also exported is the helper function `isServerSide`. Use this to determine
whether a service method is being called by the server, or by a client.

# Permissions
Permissions are a great way to restrict access to resources.

They take the form of:
* `service:foo`
* `service:create:*`
* `some:arbitrary:permission:*:with:*:a:wild:*card`

The specifics are up to you.

```dart
var permission = new Permission('admin | users:find');

// Or:
// PermissionBuilders support + and | operators. Operands can be Strings, Permissions or PermissionBuilders.
var permission = (new PermissionBuilder('admin') | (new PermissionBuilder('users') + 'find')).toPermission();

// Transform into middleware
app.chain(permission.toMiddleware()).get('/protected', ...);

// Or as a service hook
app.service('protected').beforeModify(permission.toHook());

// Dynamically create a permission hook.
// This helps in situations where the resources you need to protect are dynamic.
//
// `variantPermission` is included in the `package:angel_security/hooks.dart` library.
app.service('posts').beforeModify(variantPermission((e) {
    return new PermissionBuilder('posts:modify:${e.id}');
}));
```