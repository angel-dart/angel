# 3.0.0
* Make `Router` and `Route` single-parameter generic.
* Remove `package:browser` dependency.
* `BrowserRouter.on` now only accepts a `String`.
* `MiddlewarePipeline.routingResults` now accepts
an `Iterable<RoutingResult>`, instead of just a `List`.
* Removed deprecated `Route.as`, as well as `Router.registerMiddleware`.
* Completely removed `Route.requestMiddleware`.