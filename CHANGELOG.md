# 1.2.4+1
Fixed a bug where `Accept-Encoding` was not properly adhered to.

# 1.2.4
Fixes https://github.com/angel-dart/angel/issues/44.
* MIME types will now default to `application/octet-stream`.
* When `streamToIO` is `true`, the body will only be sent gzipped if the request explicitly allows it.

# 1.2.3
Fixed #40 and #41, which dealt with paths being improperly served when using a
`publicPath`.