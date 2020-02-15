import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'rate_limiter.dart';
import 'rate_limiting_window.dart';

/// A simple [RateLimiter] implementation that uses a simple in-memory map
/// to store rate limiting information.
class InMemoryRateLimiter<User> extends RateLimiter<User> {
  /// A callback used to compute the current user.
  final FutureOr<User> Function(RequestContext, ResponseContext) getUser;
  final _cache = <User, RateLimitingWindow<User>>{};

  InMemoryRateLimiter(
      int maxPointsPerWindow, Duration windowDuration, this.getUser,
      {String errorMessage})
      : super(maxPointsPerWindow, windowDuration, errorMessage: errorMessage);

  @override
  FutureOr<RateLimitingWindow<User>> getCurrentWindow(
      RequestContext req, ResponseContext res, DateTime currentTime) async {
    var user = await getUser(req, res);
    return _cache[user] ??= RateLimitingWindow(user, currentTime, 0);
  }

  @override
  FutureOr<void> updateCurrentWindow(RequestContext req, ResponseContext res,
      RateLimitingWindow<User> window, DateTime currentTime) {
    _cache[window.user] = window;
  }
}
