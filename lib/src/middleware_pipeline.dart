import 'router.dart';

class MiddlewarePipeline {
  final List<RoutingResult> routingResults;

  List get handlers {
    final handlers = [];

    for (RoutingResult result in routingResults) {
      handlers.addAll(result.allHandlers);
    }

    return handlers;
  }

  MiddlewarePipeline(this.routingResults);
}
