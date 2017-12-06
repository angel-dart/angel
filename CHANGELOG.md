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

# 1.0.10
* Closed [#162](https://github.com/angel-dart/framework/issues/162), fixing a caching bug
that would cause multiple requests to the same URL to fail.
* Resolved dependency injection of primitives (namely `String`), no longer triggering
errors about `String has no constructor`, etc.

# 1.0.9
* Closed [#161](https://github.com/angel-dart/framework/issues/161). `addCreated`/`addUpdatedAt` no longer
crash when `serialize` is `false`.
* Added an explicit on `charcode`, `path`, and others. Resolves
[#160](https://github.com/angel-dart/framework/issues/160).
* `ResponseContext` now implements `StreamSink<List<int>`, so data can be streamed directly to the
underlying response.
* You can now inject `encoders` into a `ResponseContext`, which takes care of `Accept-Encoding`.
This will ultimately replace `package:angel_compress`.
Resolves [#159](https://github.com/angel-dart/framework/issues/159).

# 1.0.8
* Changed `req.query` to use a modifiable Map if the body has not parsed. Resolves
[#157](https://github.com/angel-dart/framework/issues/157).
* Changed all constants to `camelCase`, and deprecated their `CONSTANT_CASE` counterparts. Resolves
[#155](https://github.com/angel-dart/framework/issues/155).
* Resolved [#156](https://github.com/angel-dart/framework/issues/156) by adding a `graphql` provider.
* Added an `analysis-options.yaml` enabling strong mode. Preparing for Dart 2.0.
* Added a dependency on `package:meta`, resolving [#154](https://github.com/angel-dart/framework/issues/154),
and added corresponding annotations to make extending Angel easier.
* Resolved [#158](https://github.com/angel-dart/framework/issues/158) by using proper `StreamController`
patterns, to prevent memory leaks.
* Route handler sequences are now cached in a Map, so repeat requests will be resolved faster.
* A message is no longer printed in production mode.
* Removed the inheritance on `Extensible` in many classes, and removed it from `angel_route`.
Now, only `Angel` and `RequestContext` have `@proxy` annotations.
* Deprecated passing `debug` to Angel.
* `_LockableBytesBuilder` now uses `Uint8List`.
* Removed `reopen` from `ResponseContext`.

# 1.0.7+2
Changed `ResponseContext.serialize`. The `contentType` is now set *before* serialization.

# 1.0.7+1
Moved the `Model` class into `package:angel_model`. No functionality was added or removed.

# 1.0.7
Added an `accepts` method to `RequestContext`. It's now a lot easier to tell which content types the
user accepts via the `Accept` header.