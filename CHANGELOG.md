# 2.2.0
* Use `http.Client` instead of `http.BaseClient`, and make it an
optional parameter.
* Allow `baseUrl` to accept `Uri` or `String`.
* Add `Proxy.pushState`.

# 2.1.2
* Apply lints.

# 2.1.1
* Update for framework@2.0.0-alpha.15

# 2.1.0

- Use `Uri` instead of archaic `host`, `port`, and `mapTo`. Also cleaner + safer + easier.

* Enable WebSocket proxying.

# 2.0.0

- Updates for Angel 2. Big thanks to @denkuy!
- Use `package:path` for better path resolution.

# 1.1.1

- Removed reference to `io`; now works with HTTP/2. Thanks to @daniel-v!
