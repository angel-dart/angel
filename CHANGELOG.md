# 2.0.0-alpha
* Removed `random_string` dependency.
* Moved reflection to `package:angel_container`.
* Upgraded `package:file` to `5.0.0`.
* `ResponseContext.sendFile` now uses `package:file`.
* Abandon `ContentType` in favor of `MediaType`.
* Changed view engine to use `Map<String, dynamic>`.
* Remove dependency on `package:json_god` by default.
* Remove dependency on `package:dart2_constant`.
* Remove `contentType` argument in `ResponseContext.serialize`.
* Moved `lib/hooks.dart` into `package:angel_hooks`.
* Moved `TypedService` into `package:angel_typed_service`.

# 1.1.5+1
* Patched annoying error that prevented MapServices from working,
simply because `<dynamic, dynamic>` is incompatible with `<String, dynamic>`.

# 1.1.5
* `AnonymousService` methods can now return `FutureOr`.
* Added `findOne` to `Service`.

# 1.1.4+11
* Close the response, etc. *after* finalizers are done.

# 1.1.4+10
* Change the zone error handler to take an `Object`

# 1.1.4+9
* Patch `ResponseContext.redirectTo` to `fold` parameters, instead of
`as`-casting them to `Map<String, dynamic>`.
* Apply this same folding to `ResponseContext.redirectToAction`.

# 1.1.4+8
* Finalizers can now write to the response buffer or send headers,
because said getter now only returns an unmodifiable Map when using
`streaming`.
* Tracked down an annoying line that printed many, many `null` messages.

# 1.1.4+7
* Remove `cast` for Dart 1.x.
* `RequestContext.injections` is no longer cached or read-only.
* `ResponseContext` now has `renderParams`.

# 1.1.4+6
* Almost 100% working with `2.0.0-dev.64.1`. In said version
of Dart, `dart:mirrors` is broken, and therefore breaks detection of metadata.

# 1.1.4+5
* Intermediary release while patching up Dart 2 bugs.
* Stricter Dart 2 use.
* Remove `AngelMetrics` for good.

# 1.1.4+4
* Fix a bug that caused a race condition in hooked services.

# 1.1.4+3
* Don't create a Stopwatch in production.
* Fix a bug where `handleAngelHttpException` created a race condition.
* `ResponseContext.serialize` now returns a `bool`.

# 1.1.4+2
* Fix a bug that prevented proper rendering of views.
* Fixed a hidden bug that prevents error handling when a
stack trace is `null`.
* Fixed a bug that prevented proper handling of `content-encoding`.

# 1.1.4+1
* Ensure correct error handling when `useZone` is `false`.
 
# 1.1.4
* Remove all usages of `async`/`await` in the core library.
* `AngelConfigurer` now accepts `FutureOr`.
* `AngelHttp` now has a `useZone` flag to disable custom zones.

# 1.1.3
* `AngelHttp` now handles requests in a `Zone`.
* Use `package:dart2_constant`.

# 1.1.2
* `MapService` will store `created_at` and `updated_at` as `String`.

# 1.1.1
* `ResponseContext` no longer automatically closes if `serializer` returns an
empty string.
* Added `autoSnakeCaseNames` to `MapService`.
* Deprecated `Angel.createZoneForRequest`.
* Deprecated all `Angel` methods that directly touch an `HttpServer` or `HttpRequest`.
* Created the `AngelHttp` class.
* Removed explicit dependence on `dart:io` for `Angel`, `RequestContext`, `ResponseContext`.
* Created `lib/http.dart`, which exports HTTP-specific functionality.
* `AnonymousService` now takes `FutureOr`.
* `Service.toId` no longer only takes a `String`, and is generically-typed.

# 1.1.0+3
* Modified `ResponseContext#isOpen` to also return `false` if streaming is being used.

# 1.1.0+2
* Modified `handleAngelHttpException` to only run rescue code
if the response is still open. Prevents application crashes.

# 1.1.0+1
* Modified `_matchesId` in `MapService` to support custom ID fields.

# 1.1.0
* The default `errorHandler` now only sends HTML if the user explicitly accepts it.

# 1.1.0-alpha+9
* Fixed a bug that prevented `isProduction` from ever returning `true`.
    * This enabled caching, which greatly improved performance.
* Requests no longer have independent zones, which greatly improved performance.
* `FormatException`, when caught, is automatically transformed in a `400` error response.
* Added `extension` to `RequestContext`.
* Added `strict` to `RequestContext#accepts`.
* Added a `toString` override for the `Providers` class.
* Returned to `RegExp` for stripping stray slashes.
* The request path is now only parsed once.
* Optimized the parsing of the `ACCEPT_ENCODING` header.

# 1.1.0-alpha+8
* Added an `autoIdAndDateFields` flag to `MapService`. Finally.

# 1.1.0-alpha+7
* Made `handlerCache` public.
* Added `AngelMetrics`.

# 1.1.0-alpha+6
* Added `@Parameter()` annotations, with support for pattern matching.

# 1.1.0-alpha+5
* Closed [#166](https://github.com/angel-dart/framework/issues/166), killing any hanging `Stopwatch` instances when streaming.
* Removed `AngelPlugin` and `AngelMiddleware`, as well as the `@proxy` annotations from `Angel` and `RequestContext`.
* Officially deprecated `properties` in `Angel`.
* Fixed a bug where cached routes would not heed the request method. [#173](https://github.com/angel-dart/framework/issues/173)
* Reworked error handling logic; now, errors will not automatically default to sending JSON.
* Removed the `onController` stream from `Angel`.
* Controllers now longer use `call`, which has now been renamed to `configureServer`.

# 1.1.0-alpha+4
* Made `injections` in `RequestContext` private.
* Renamed `properties` in `AngelBase` to `configuration`.

# 1.1.0-alpha+3
* Fixed a bug where `encoders` would cause a malformed response to be sent.
* Fixed a bug where `encoders` would not always use the correct encoder.

# 1.1.0-alpha
* Removed `AngelFatalError`, and subsequently `fatalErrorStream`.
* Removed all `@deprecated` members.
* Removed `@Hooked`, `beforeProcessed`, and `afterProcessed`.