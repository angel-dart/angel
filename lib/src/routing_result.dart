part of angel_route.src.router;

/// Represents a complex result of navigating to a path.
class RoutingResult {
  /// The Regex match that matched the given sub-path.
  final Match match;

  /// A nested instance, if a sub-path was matched.
  final RoutingResult nested;

  /// All route params matching this route on the current sub-path.
  final Map<String, dynamic> params = {};

  /// The [Route] that answered this sub-path.
  ///
  /// This is mostly for internal use, and useless in production.
  final Route shallowRoute;

  /// The [Router] that answered this sub-path.
  ///
  /// Only really for internal use.
  final Router shallowRouter;

  /// The remainder of the full path that was not matched, and was passed to [nested] routes.
  final String tail;

  /// The [RoutingResult] that matched the most specific sub-path.
  RoutingResult get deepest {
    var search = this;

    while (search.nested != null) search = search.nested;

    return search;
  }

  /// The most specific route.
  Route get route => deepest.shallowRoute;

  /// The most specific router.
  Router get router => deepest.shallowRouter;

  /// The handlers at this sub-path.
  List get handlers {
    return []..addAll(shallowRouter.middleware)..addAll(shallowRoute.handlers);
  }

  /// All handlers on this sub-path and its children.
  List get allHandlers {
    final handlers = [];
    var search = this;

    while (search != null) {
      handlers.addAll(search.handlers);
      search = search.nested;
    }

    return handlers;
  }

  /// All parameters on this sub-path and its children.
  Map<String, dynamic> get allParams {
    final Map<String, dynamic> params = {};
    var search = this;

    while (search != null) {
      params.addAll(search.params);
      search = search.nested;
    }

    return params;
  }

  RoutingResult(
      {this.match,
      Map<String, dynamic> params: const {},
      this.nested,
      this.shallowRoute,
      this.shallowRouter,
      this.tail}) {
    this.params.addAll(params ?? {});
  }
}
