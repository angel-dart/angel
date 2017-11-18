# 1.3.1
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