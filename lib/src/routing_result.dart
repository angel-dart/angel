part of angel_route.src.router;

class RoutingResult {
  final Match match;
  final RoutingResult nested;
  final Map<String, dynamic> params = {};
  final Route shallowRoute;
  final Router shallowRouter;
  final String tail;

  RoutingResult get deepest {
    var search = this;

    while (search.nested != null) search = search.nested;

    return search;
  }

  Route get route => deepest.shallowRoute;
  Router get router => deepest.shallowRouter;

  List get handlers {
    return []..addAll(shallowRouter.middleware)..addAll(shallowRoute.handlers);
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
      this.shallowRoute,
      this.shallowRouter,
      this.tail}) {
    this.params.addAll(params ?? {});
  }
}
