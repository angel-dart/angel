import 'router.dart';

/// A chain of arbitrary handlers obtained by routing a path.
class MiddlewarePipeline {
  /// All the possible routes that matched the given path.
  final List<RoutingResult> routingResults;
  List _handlers;

  /// An ordered list of every handler delegated to handle this request.
  List get handlers {
    if (_handlers != null) return _handlers;
    final handlers = [];

    for (RoutingResult result in routingResults) {
      handlers.addAll(result.allHandlers);
    }

    return _handlers = handlers;
  }

  MiddlewarePipeline(Iterable<RoutingResult> routingResults)
      : this.routingResults = routingResults.toList();
}
