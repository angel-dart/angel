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