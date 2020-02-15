# 3.1.0+1
* Accidentally hit `CTRL-C` while uploading `3.1.0`; this version ensures everything is ok.

# 3.1.0
* Add `Router.groupAsync`

# 3.0.6
* Remove static default values for `middleware`.

# 3.0.5
* Add `MiddlewarePipelineIterator`.

# 3.0.4
* Add `RouteResult` class, which allows segments (i.e. wildcard) to
modify the `tail`.
* Add more wildcard tests.

# 3.0.3
* Support trailing text after parameters with custom Regexes.

# 3.0.2
* Support leading and trailing text for both `:parameters` and `*`

# 3.0.1
* Make the callback in `Router.group` generically-typed.

# 3.0.0
* Make `Router` and `Route` single-parameter generic.
* Remove `package:browser` dependency.
* `BrowserRouter.on` now only accepts a `String`.
* `MiddlewarePipeline.routingResults` now accepts
an `Iterable<RoutingResult>`, instead of just a `List`.
* Removed deprecated `Route.as`, as well as `Router.registerMiddleware`.
* Completely removed `Route.requestMiddleware`.

# 2.0.7
* Minor strong mode updates to work with stricter Dart 2.

# 2.0.5
* Patch to work with `combinator@1.0.0`.