/// A representation of the abstract "rate-limiting window" in which
/// a [user] is accessing some API or endpoint.
class RateLimitingWindow<User> {
  /// The user who is accessing the endpoint.
  User user;

  /// The time at which the user's current window began.
  DateTime startTime;

  /// The number of points the user has already consumed within
  /// the current window.
  int pointsConsumed;

  /// The maximum amount of points allowed within a single window.
  ///
  /// This field is typically only set by the [RateLimiter] middleware,
  /// and is therefore optional in the constructor.
  int pointLimit;

  /// The amount of points the user can consume before hitting the
  /// rate limit for the current window.
  ///
  /// This field is typically only set by the [RateLimiter] middleware,
  /// and is therefore optional in the constructor.
  int remainingPoints;

  /// The time at which the window will reset.
  ///
  /// This field is typically only set by the [RateLimiter] middleware,
  /// and is therefore optional in the constructor.
  DateTime resetTime;

  RateLimitingWindow(this.user, this.startTime, this.pointsConsumed,
      {this.pointLimit, this.remainingPoints, this.resetTime});

  factory RateLimitingWindow.fromJson(Map<String, dynamic> map) {
    return RateLimitingWindow(
        map['user'] as User,
        DateTime.parse(map['start_time'] as String),
        int.parse(map['points_consumed'] as String));
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'start_time': startTime.toIso8601String(),
      'points_consumed': pointsConsumed.toString(),
    };
  }
}
