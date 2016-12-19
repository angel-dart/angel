import 'router.dart';

/// A chain of arbitrary handlers obtained by routing a path.
class MiddlewarePipeline {
  /// All the possible routes that matched the given path.
  final List<RoutingResult> routingResults;

  /// An ordered list of every handler delegated to handle this request.
  List get handlers {
    final handlers = [];

    for (RoutingResult result in routingResults) {
      handlers.addAll(result.allHandlers);
    }

    return handlers;
  }

  MiddlewarePipeline(this.routingResults);
}
