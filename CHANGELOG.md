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
* Removed the synchronous equivalents of the above methods (`body`, `files`, and `originalBuffer`).