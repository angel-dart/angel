/// A representation of the abstract "rate-limiting window" in which
/// a [user] is accessing some API or endpoint.
class RateLimitingWindow<User> {
  /// The user who is accessing the endpoint.
  final User user;

  /// The time at which the user's current window began.
  final DateTime start;

  /// The number of requests the user has already sent within
  /// the current window.
  final int requestCount;

  /// The maximum amount of points allowed within a single window.
  final int pointLimit;

  /// The amount of points the user can consume before hitting the
  /// rate limit for the current window.
  final int remainingPoints;

  /// The time at which the window will reset.
  final DateTime resetsAt;

  RateLimitingWindow(this.user, this.start, this.requestCount,
      {this.pointLimit, this.remainingPoints, this.resetsAt});
}
