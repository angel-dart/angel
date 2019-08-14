import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_security/angel_security.dart';
import 'rate_limiting_window.dart';

/// A base class that facilitates rate limiting API's or endpoints,
/// typically to prevent spam and abuse.
///
/// The rate limiter operates under the assumption that a [User] object
/// can be computed from each request, as well as information about
/// the current rate-limiting window.
abstract class RateLimiter<User> {
  /// The maximum number of requests allowed within the given [window].
  final int maxRequestsPerWindow;

  /// The amount of time, during which, a user is not allowed to send
  /// more than [maxRequestsPerWindow].
  final Duration window;

  RateLimiter(this.maxRequestsPerWindow, this.window);

  /// Computes the current window in which the user is acting.
  /// 
  /// For example, if your API was limited to 1000 requests/hour,
  /// then you would return a window containing the current hour,
  /// and the number of requests the user has sent in the past hour.
  FutureOr<RateLimitingWindow<User>> getCurrentWindow(
      RequestContext req, ResponseContext res);

  /// Updates the underlying store with information about the
  /// [newWindow] that the user is operating in.
  FutureOr<void> updateCurrentWindow(RequestContext req, ResponseContext res,
      RateLimitingWindow<User> newWindow);

  FutureOr<Object> denyRequest(RequestContext req, ResponseContext res) {
    
  }
}
