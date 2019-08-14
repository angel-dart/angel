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
  /// The maximum number of points that may be consumed
  /// within the given [windowDuration].
  final int maxPointsPerWindow;

  /// The amount of time, during which, a user is not allowed to consume
  /// more than [maxPointsPerWindow].
  final Duration windowDuration;

  /// The error message to send to a [User] who has exceeded the
  /// rate limit during the current window.
  ///
  /// This only applies to the default implementation of
  /// [denyRequest].
  final String errorMessage;

  RateLimiter(this.maxPointsPerWindow, this.windowDuration,
      {this.errorMessage});

  /// Computes the current window in which the user is acting.
  ///
  /// For example, if your API was limited to 1000 requests/hour,
  /// then you would return a window containing the current hour,
  /// and the number of requests the user has sent in the past hour.
  FutureOr<RateLimitingWindow<User>> getCurrentWindow(
      RequestContext req, ResponseContext res);

  /// Updates the underlying store with information about the new
  /// [window] that the user is operating in.
  FutureOr<void> updateCurrentWindow(
      RequestContext req, ResponseContext res, RateLimitingWindow<User> window);

  /// Computes the amount of points that a given request will cost. This amount
  /// is then added to the amount of points that the user has already consumed
  /// in the current [window].
  ///
  /// The default behavior is to return `1`, which signifies that all requests
  /// carry the same weight.
  FutureOr<int> getEndpointCost(RequestContext req, ResponseContext res,
      RateLimitingWindow<User> window) {
    return Future<int>.value(1);
  }

  /// Signals to a user that they have exceeded the rate limit for the
  /// current window.
  ///
  /// The default implementation is throw an [AngelHttpException] with
  /// status code `429` and the given `errorMessage`, as well as sending
  /// a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429)
  /// header, and then returning `false`.
  ///
  /// Whatever is returned here will be returned in [handleRequest].
  FutureOr<Object> denyRequest(RequestContext req, ResponseContext res,
      RateLimitingWindow<User> window) {}
}
