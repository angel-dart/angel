import 'router.dart';

/// A chain of arbitrary handlers obtained by routing a path.
class MiddlewarePipeline<T> {
  /// All the possible routes that matched the given path.
  final Iterable<RoutingResult<T>> routingResults;
  List<T> _handlers;

  /// An ordered list of every handler delegated to handle this request.
  List<T> get handlers {
    if (_handlers != null) return _handlers;
    final handlers = <T>[];

    for (var result in routingResults) {
      handlers.addAll(result.allHandlers);
    }

    return _handlers = handlers;
  }

  MiddlewarePipeline(this.routingResults);
}
