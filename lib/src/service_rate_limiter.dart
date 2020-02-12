import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'rate_limiter.dart';
import 'rate_limiting_window.dart';

/// A RateLimiter] implementation that uses a [Service]
/// to store rate limiting information.
class ServiceRateLimiter<Id> extends RateLimiter<Id> {
  /// The underlying [Service] used to store data.
  final Service<Id, Map<String, dynamic>> service;

  /// A callback used to compute the current user ID.
  final FutureOr<Id> Function(RequestContext, ResponseContext) getId;

  ServiceRateLimiter(
      int maxPointsPerWindow, Duration windowDuration, this.service, this.getId,
      {String errorMessage})
      : super(maxPointsPerWindow, windowDuration, errorMessage: errorMessage);

  @override
  FutureOr<RateLimitingWindow<Id>> getCurrentWindow(
      RequestContext req, ResponseContext res, DateTime currentTime) async {
    var id = await getId(req, res);
    try {
      var data = await service.read(id);
      if (data != null) {
        return RateLimitingWindow.fromJson(data);
      }
    } catch (e) {
      if (e is AngelHttpException) {
        if (e.statusCode == 404) {
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    var window = RateLimitingWindow(id, currentTime, 0);
    await updateCurrentWindow(req, res, window, currentTime);
    return window;
  }

  @override
  FutureOr<void> updateCurrentWindow(RequestContext req, ResponseContext res,
      RateLimitingWindow<Id> window, DateTime currentTime) async {
    await service.update(window.user, window.toJson());
  }
}
