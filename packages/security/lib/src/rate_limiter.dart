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
  /// [rejectRequest].
  final String errorMessage;

  RateLimiter(this.maxPointsPerWindow, this.windowDuration,
      {String errorMessage})
      : this.errorMessage = errorMessage ?? 'Rate limit exceeded.';

  /// Computes the current window in which the user is acting.
  ///
  /// For example, if your API was limited to 1000 requests/hour,
  /// then you would return a window containing the current hour,
  /// and the number of requests the user has sent in the past hour.
  FutureOr<RateLimitingWindow<User>> getCurrentWindow(
      RequestContext req, ResponseContext res, DateTime currentTime);

  /// Updates the underlying store with information about the new
  /// [window] that the user is operating in.
  FutureOr<void> updateCurrentWindow(RequestContext req, ResponseContext res,
      RateLimitingWindow<User> window, DateTime currentTime);

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

  /// Alerts the user of information pertinent to the current [window].
  ///
  /// The default implementation is to send the following headers, akin to
  /// Github's v4 Graph API:
  /// * `X-RateLimit-Limit`: The maximum number of points consumed per window.
  /// * `X-RateLimit-Remaining`: The remaining number of points that may be consumed
  /// before the rate limit is reached for the current window.
  /// * `X-RateLimit-Reset`: The Unix timestamp, at which the window will
  /// reset.
  FutureOr<void> sendWindowInformation(RequestContext req, ResponseContext res,
      RateLimitingWindow<User> window) {
    res.headers.addAll({
      'x-ratelimit-limit': window.pointLimit.toString(),
      'x-ratelimit-remaining': window.remainingPoints.toString(),
      'x-ratelimit-reset':
          (window.resetTime.millisecondsSinceEpoch ~/ 1000).toString(),
    });
  }

  /// Signals to a user that they have exceeded the rate limit for the
  /// current window, and terminates execution of the current [RequestContext].
  ///
  /// The default implementation is throw an [AngelHttpException] with
  /// status code `429` and the given `errorMessage`, as well as sending
  /// a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429)
  /// header, and then returning `false`.
  ///
  /// Whatever is returned here will be returned in [handleRequest].
  FutureOr<Object> rejectRequest(RequestContext req, ResponseContext res,
      RateLimitingWindow<User> window, DateTime currentTime) {
    var retryAfter = window.resetTime.difference(currentTime);
    res.headers['retry-after'] = retryAfter.inSeconds.toString();
    throw AngelHttpException(null, message: errorMessage, statusCode: 429);
  }

  /// A request middleware that returns `true` if the user has not yet
  /// exceeded the [maxPointsPerWindow].
  ///
  /// Because this handler is typically called *before* business logic is
  /// executed, it technically checks whether the *previous* call raised the
  /// number of consumed points to greater than, or equal to, the
  /// [maxPointsPerWindow].
  Future handleRequest(RequestContext req, ResponseContext res) async {
    // Obtain information about the current window.
    var now = DateTime.now().toUtc();
    var currentWindow = await getCurrentWindow(req, res, now);
    // Check if the rate limit has been exceeded. If so, reject the request.
    // To perform this check, we must first determine whether a new window
    // has begun since the previous request.
    var currentWindowEnd = currentWindow.startTime.toUtc().add(windowDuration);
    // We must also compute the missing information about the current window,
    // so that we can relay that information to the client.
    var remainingPoints = maxPointsPerWindow - currentWindow.pointsConsumed;
    currentWindow
      ..pointLimit = maxPointsPerWindow
      ..remainingPoints = remainingPoints < 0 ? 0 : remainingPoints
      ..resetTime = currentWindow.startTime.add(windowDuration);

    // If the previous window ended in the past, begin a new window.
    if (now.compareTo(currentWindowEnd) >= 0) {
      // Create a new window.
      var cost = await getEndpointCost(req, res, currentWindow);
      var remainingPoints = maxPointsPerWindow - cost;
      var newWindow = RateLimitingWindow(currentWindow.user, now, cost)
        ..pointLimit = maxPointsPerWindow
        ..remainingPoints = remainingPoints < 0 ? 0 : remainingPoints
        ..resetTime = now.add(windowDuration);
      await updateCurrentWindow(req, res, newWindow, now);
      await sendWindowInformation(req, res, newWindow);
    }

    // If we are still within the previous window, check if the user has
    // exceeded the rate limit.
    //
    // Otherwise, update the current window.
    //
    // At this point in the computation,
    // we are still only considering whether the *previous* request took the
    // user over the rate limit.
    else if (currentWindow.pointsConsumed >= maxPointsPerWindow) {
      await sendWindowInformation(req, res, currentWindow);
      var result = await rejectRequest(req, res, currentWindow, now);
      if (result != null) return result;
      return false;
    } else {
      // Add the cost of the current endpoint, and update the window.
      var cost = await getEndpointCost(req, res, currentWindow);
      currentWindow
        ..pointsConsumed += cost
        ..remainingPoints -= cost;
      if (currentWindow.remainingPoints < 0) {
        currentWindow.remainingPoints = 0;
      }
      await updateCurrentWindow(req, res, currentWindow, now);
      await sendWindowInformation(req, res, currentWindow);
    }

    // Pass through, so other handlers can be executed.
    return true;
  }
}
