part of angel_route.src.router;

class RoutingResult {
  final Match match;
  final RoutingResult nested;
  final Map<String, dynamic> params = {};
  final Route sourceRoute;
  final Router sourceRouter;
  final String tail;

  RoutingResult get deepest {
    var search = this;

    while (search.nested != null) search = search.nested;

    return search;
  }

  Route get deepestRoute => deepest.sourceRoute;
  Router get deepestRouter => deepest.sourceRouter;

  List get handlers {
    return []..addAll(sourceRouter.middleware)..addAll(sourceRoute.handlers);
  }

  List get allHandlers {
    final handlers = [];
    var search = this;

    while (search != null) {
      handlers.addAll(search.handlers);
      search = search.nested;
    }

    return handlers;
  }

  RoutingResult(
      {this.match,
      Map<String, dynamic> params: const {},
      this.nested,
      this.sourceRoute,
      this.sourceRouter,
      this.tail}) {
    this.params.addAll(params ?? {});
  }
}
