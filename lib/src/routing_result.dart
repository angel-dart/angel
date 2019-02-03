part of angel_route.src.router;

/// Represents a complex result of navigating to a path.
class RoutingResult<T> {
  /// The parse result that matched the given sub-path.
  final ParseResult<RouteResult> parseResult;

  /// A nested instance, if a sub-path was matched.
  final Iterable<RoutingResult<T>> nested;

  /// All route params matching this route on the current sub-path.
  final Map<String, dynamic> params = {};

  /// The [Route] that answered this sub-path.
  ///
  /// This is mostly for internal use, and useless in production.
  final Route<T> shallowRoute;

  /// The [Router] that answered this sub-path.
  ///
  /// Only really for internal use.
  final Router<T> shallowRouter;

  /// The remainder of the full path that was not matched, and was passed to [nested] routes.
  final String tail;

  /// The [RoutingResult] that matched the most specific sub-path.
  RoutingResult<T> get deepest {
    var search = this;

    while (search?.nested?.isNotEmpty == true) search = search.nested.first;

    return search;
  }

  /// The most specific route.
  Route<T> get route => deepest.shallowRoute;

  /// The most specific router.
  Router<T> get router => deepest.shallowRouter;

  /// The handlers at this sub-path.
  List<T> get handlers {
    return <T>[]
      ..addAll(shallowRouter.middleware)
      ..addAll(shallowRoute.handlers);
  }

  /// All handlers on this sub-path and its children.
  List<T> get allHandlers {
    final handlers = <T>[];

    void crawl(RoutingResult<T> result) {
      handlers.addAll(result.handlers);

      if (result.nested?.isNotEmpty == true) {
        for (var r in result.nested) crawl(r);
      }
    }

    crawl(this);

    return handlers;
  }

  /// All parameters on this sub-path and its children.
  Map<String, dynamic> get allParams {
    final Map<String, dynamic> params = {};

    void crawl(RoutingResult result) {
      params.addAll(result.params);

      if (result.nested?.isNotEmpty == true) {
        for (var r in result.nested) crawl(r);
      }
    }

    crawl(this);
    return params;
  }

  RoutingResult(
      {this.parseResult,
      Map<String, dynamic> params: const {},
      this.nested,
      this.shallowRoute,
      this.shallowRouter,
      @required this.tail}) {
    this.params.addAll(params ?? {});
  }
}
