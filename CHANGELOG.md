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
* Completely removed the `AngelBase` class.
* Removed all `@deprecated` symbols.
* `Service.toId` was renamed to `Service.parseId`; it also now uses its
single type argument to determine how to parse a value.
    * In addition, this method was also made `static`.
* `RequestContext` and `ResponseContext` are now generic, and take a
single type argument pointing to the underlying request/response type,
respectively.
* `RequestContext.io` and `ResponseContext.io` are now permanently
gone.
* `HttpRequestContextImpl` and `HttpResponseContextImpl` were renamed to
`HttpRequestContext` and `HttpResponseContext`.
* Lazy-parsing request bodies is now the default; `Angel.lazyParseBodies` was replaced
with `Angel.eagerParseRequestBodies`.
* `Angel.storeOriginalBuffer` -> `Angel.storeRawRequestBuffers`.
* The methods `lazyBody`, `lazyFiles`, and `lazyOriginalBuffer` on `ResponseContext` were all
replaced with `parseBody`, `parseUploadedFiles`, and `parseRawRequestBuffer`, respectively.
* Removed the synchronous equivalents of the above methods (`body`, `files`, and `originalBuffer`),
as well as `query`.
* Removed `Angel.injections` and `RequestContext.injections`.
* Removed `Angel.inject` and `RequestContext.inject`.
* Removed a dependency on `package:pool`, which also meant removing `AngelHttp.throttle`.
* Remove the `RequestMiddleware` typedef; from now on, one should use `ResponseContext.end`
exclusively to close responses.
* `waterfall` will now only accept `RequestHandler`.
* `Routable`, and all of its subclasses, now extend `Router<RequestHandler>`, and therefore only
take routes in the form of `FutureOr myFunc(RequestContext, ResponseContext res)`.
* `@Middleware` now takes an `Iterable` of `RequestHandler`s.
* `@Expose.path` now *must* be a `String`, not just any `Pattern`.
* `@Expose.middleware` now takes `Iterable<RequestHandler>`, instead of just `List`.
* `createDynamicHandler` was renamed to `ioc`, and is now used to run IoC-aware handlers in a
type-safe manner.
* `RequestContext.params` is now a `Map<String, dynamic>`, rather than just a `Map`.
* Removed `RequestContext.grab`.
* Removed `RequestContext.properties`.
* Removed the defunct `debug` property where it still existed.
* `Routable.use` now only accepts a `Service`.
* The above change removes the concept of "nested apps," which are messy to maintain, and
not very elegant.
* Removed `Angel.createZoneForRequest`.
* Removed `Angel.defaultZoneCreator`.
* Added all flags to the `Angel` constructor, ex. `Angel.eagerParseBodies`.