# 2.1.3+2
* Prepare for upcoming change to File.openRead()

# 2.1.3+1
* Apply control flow lints.

# 2.1.3
* Apply lints.
* Pin to Dart `>=2.0.0 <3.0.0`.
* Use at least version `2.0.0-rc.0` of `angel_framework`.

# 2.1.2+1
* Fix a typo that prevented `Range` requests from working.

# 2.1.2
* Patch support for range+streaming in Caching server.

# 2.1.1
* URI-encode paths in directory listing. This produces correct URL's, always.

# 2.1.0
* Include support for the `Range` header.
* Use MD5 for etags, instead of a weak ETag.

# 2.0.2
* Fixed invalid HTML for directory listings.

# 2.0.1
* Remove use of `sendFile`.
* Add a `p.isWithin` check to ensure that paths do not escape the `source` directory.
* Handle `HEAD` requests.

# 2.0.0
* Upgrade dependencies to Angel 2 + file@5.
* Replace `useStream` with `useBuffer`.
* Remove `package:intl`, just use `HttpDate` instead.

# 1.3.0+1
* Dart 2 fixes.
* Enable optionally writing responses to the buffer instead of streaming.

# 1.3.0
* `pushState` uses `strict` mode when `accepts` is passed.

# 1.3.0-alpha+2
* Added an `accepts` option to `pushState`.
* Added optional directory listings.

# 1.3.0-alpha+1
* ETags once again only encode the first 50 bytes of files. Resolves [#27](https://github.com/angel-dart/static/issues/27).

# 1.3.0-alpha
* Removed file transformers.
* `VirtualDirectory` is no longer an `AngelPlugin`, and instead exposes a `handleRequest` middleware.
* Added `pushState` to `VirtualDirectory`.

# 1.2.5
* Fixed a bug where `onlyInProduction` was not properly adhered to.
* Fixed another bug where `Accept-Encoding` was not properly adhered to.
* Setting `maxAge` to `null` will now prevent a `CachingVirtualDirectory` from sending an `Expires` header.
* Pre-built assets can now be mass-deleted with `VirtualDirectory.cleanFromDisk()`.
Resolves [#22](https://github.com/angel-dart/static/issues/22).

# 1.2.4+1
Fixed a bug where `Accept-Encoding` was not properly adhered to.

# 1.2.4
Fixes https://github.com/angel-dart/angel/issues/44.
* MIME types will now default to `application/octet-stream`.
* When `streamToIO` is `true`, the body will only be sent gzipped if the request explicitly allows it.

# 1.2.3
Fixed #40 and #41, which dealt with paths being improperly served when using a
`publicPath`.
